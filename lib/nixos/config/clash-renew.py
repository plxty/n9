#!/usr/bin/env python3

import os
import time
import subprocess
import yaml
import traceback

SOURCE = "/etc/mihomo/original.yaml"
TARGET = "/etc/mihomo/clash.yaml"


def main():
    if os.path.isfile(SOURCE) and (time.time() - os.path.getmtime(SOURCE) < 86400):
        return

    with open("/etc/mihomo/subscribe", "r") as reader:
        subscribe = reader.read().encode("ascii").strip()
    subprocess.check_call(["curl", "-o", SOURCE, subscribe])
    os.chmod(SOURCE, 0o600)
    with open(SOURCE, "r") as reader:
        config = yaml.safe_load(reader)

    # override what we want:
    # https://wiki.metacubex.one/en/example/conf/
    config["profile"] = {"store-fake-ip": True}
    config["tproxy-port"] = 7892  # TODO: cleanup ports
    config["log-level"] = "warning"
    config["ipv6"] = True
    config["dns"]["ipv6"] = True
    config["dns"]["enhanced-mode"] = "fake-ip"
    config["dns"]["fake-ip-range"] = "198.18.0.0/15"  # TODO: 10.64.0.0/10
    config["dns"]["fake-ip-filter-mode"] = "whitelist"
    config["dns"]["fake-ip-filter"] = [  # should return the fake ip
        "services.googleapis.cn",
        "geosite:geolocation-!cn",
    ]
    config["dns"]["fake-ip-reverse"] = [  # should return the real ip
        "+.hut.pen.guru",
        "+.alibaba-inc.com",
        "+.yunos-inc.com",
    ]
    config["geodata-mode"] = True
    config["geox-url"] = {
        "geoip": "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat",
        "geosite": "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat",
    }
    config["proxy-groups"] += [
        {
            "name": "ThroughJapan",
            "proxies": [
                "\U0001f1fa\U0001f1f8 \u7f8e\u56fd 01",
                "\U0001f1fa\U0001f1f8 \u7f8e\u56fd 02",
                "\U0001f1fa\U0001f1f8 \u7f8e\u56fd 03",
                "\U0001f1fa\U0001f1f8 \u7f8e\u56fd 04",
                "\U0001f1fa\U0001f1f8 \u7f8e\u56fd 05",
                "\U0001f1fa\U0001f1f8 \u7f8e\u56fd 06",
                "\U0001f1fa\U0001f1f8 \u7f8e\u56fd 07",
                "\U0001f1fa\U0001f1f8 \u7f8e\u56fd 08",
                "\U0001f1fa\U0001f1f8 \u7f8e\u56fd 09",
                "\U0001f1fa\U0001f1f8 \u7f8e\u56fd 10",
                "\U0001f1fa\U0001f1f8 \u7f8e\u56fd 11",
                "\U0001f1fa\U0001f1f8 \u7f8e\u56fd 12",
                "\U0001f1fa\U0001f1f8 \u7f8e\u56fd 13",
            ],
            "type": "select",
        },
    ]
    config["rules"] += [
        "DOMAIN-SUFFIX,ototoy.jp,ThroughJapan",
    ]

    # dump again
    with open(TARGET, "w") as writer:
        writer.write(yaml.dump(config))
    os.chmod(TARGET, 0o600)

    return 0


if __name__ == "__main__":
    __return__ = 0
    try:
        __return__ = main()
    except Exception:
        print(traceback.format_exc())

    # Always ignore the error, try not to block the mihomo.
    # When we failed, we may still reuse the old configurations.
    if __return__ != 0:
        print("ERROR returns", __return__)
    exit(0)
