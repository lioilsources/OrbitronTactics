#!/usr/bin/env python3
"""Upload docs/store/screenshots_{ios,ipad}/<lang>/*.png to App Store Connect.

Replaces every screenshot in the iPhone 6.9" and iPad 13" sets of each
localization of the editable App Store version, in file-name order.

  APP_STORE_CONNECT_API_KEY_PATH=<fastlane api key json> \
  ASC_CLIENT_DIR=<dir with asc.py> python3 tools/store/upload_app_store_screenshots.py

Render the images first: STORE_SCREENSHOTS=1 flutter test test/store_screenshots
"""
import glob
import hashlib
import os
import sys
import urllib.request

sys.path.insert(0, os.environ.get(
    "ASC_CLIENT_DIR", os.path.expanduser("~/Dev/GitHub/Store/store-ops/scripts")))
from asc import call  # noqa: E402

APP_ID = "6786616881"
ROOT = os.path.join(os.path.dirname(__file__), "..", "..", "docs", "store")
# ASC locale -> screenshot language folder
LOCALES = {"en-GB": "en", "en-US": "en", "cs": "cs"}
# ASC display type -> folder under docs/store
SETS = {"APP_IPHONE_67": "screenshots_ios", "APP_IPAD_PRO_3GEN_129": "screenshots_ipad"}
EDITABLE = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
            "METADATA_REJECTED", "INVALID_BINARY"}


def upload(set_id, path):
    data = open(path, "rb").read()
    shot = call("/v1/appScreenshots", "POST", {"data": {
        "type": "appScreenshots",
        "attributes": {"fileName": os.path.basename(path), "fileSize": len(data)},
        "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}},
    }})["data"]
    for op in shot["attributes"]["uploadOperations"]:
        part = data[op["offset"]:op["offset"] + op["length"]]
        req = urllib.request.Request(op["url"], part, method=op["method"])
        for h in op["requestHeaders"]:
            req.add_header(h["name"], h["value"])
        urllib.request.urlopen(req).read()
    call(f"/v1/appScreenshots/{shot['id']}", "PATCH", {"data": {
        "type": "appScreenshots", "id": shot["id"],
        "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()},
    }})


def main():
    versions = call(f"/v1/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS")["data"]
    version = next(v for v in versions if v["attributes"]["appStoreState"] in EDITABLE)
    locs = call(f"/v1/appStoreVersions/{version['id']}/appStoreVersionLocalizations")["data"]
    for loc in locs:
        lang = LOCALES.get(loc["attributes"]["locale"])
        if not lang:
            continue
        sets = {s["attributes"]["screenshotDisplayType"]: s["id"] for s in call(
            f"/v1/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets")["data"]}
        for display, folder in SETS.items():
            files = sorted(glob.glob(os.path.join(ROOT, folder, lang, "*.png")))
            if not files:
                continue
            set_id = sets.get(display) or call("/v1/appScreenshotSets", "POST", {"data": {
                "type": "appScreenshotSets",
                "attributes": {"screenshotDisplayType": display},
                "relationships": {"appStoreVersionLocalization": {"data": {
                    "type": "appStoreVersionLocalizations", "id": loc["id"]}}},
            }})["data"]["id"]
            for old in call(f"/v1/appScreenshotSets/{set_id}/appScreenshots")["data"]:
                call(f"/v1/appScreenshots/{old['id']}", "DELETE")
            for path in files:
                upload(set_id, path)
            print(loc["attributes"]["locale"], display, len(files))


if __name__ == "__main__":
    main()
