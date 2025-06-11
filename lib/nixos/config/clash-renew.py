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
                "\U0001F1FA\U0001F1F8 \u7F8E\u56FD 01",
                "\U0001F1FA\U0001F1F8 \u7F8E\u56FD 02",
                "\U0001F1FA\U0001F1F8 \u7F8E\u56FD 03",
                "\U0001F1FA\U0001F1F8 \u7F8E\u56FD 04",
                "\U0001F1FA\U0001F1F8 \u7F8E\u56FD 05",
                "\U0001F1FA\U0001F1F8 \u7F8E\u56FD 06",
                "\U0001F1FA\U0001F1F8 \u7F8E\u56FD 07",
                "\U0001F1FA\U0001F1F8 \u7F8E\u56FD 08",
                "\U0001F1FA\U0001F1F8 \u7F8E\u56FD 09",
                "\U0001F1FA\U0001F1F8 \u7F8E\u56FD 10",
                "\U0001F1FA\U0001F1F8 \u7F8E\u56FD 11",
                "\U0001F1FA\U0001F1F8 \u7F8E\u56FD 12",
                "\U0001F1FA\U0001F1F8 \u7F8E\u56FD 13",
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
    try:
        __return__ = main()
    except Exception:
        print(f"error={__return__}", traceback.format_exc())
