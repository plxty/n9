#!/usr/bin/env python3

import os
import sys
import subprocess
import yaml
import traceback

PRIVATE = "/var/lib/private/mihomo"
GEO_IP = PRIVATE + "/GeoIP.dat"
GEO_SITE = PRIVATE + "/GeoSite.dat"
SOURCE = "/etc/mihomo/original.yaml"
TARGET = "/etc/mihomo/clash.yaml"


def main():
    if os.getuid() != 0:
        print("run me in root")
        return 0

    os.makedirs(os.path.dirname(SOURCE), exist_ok=True)
    subprocess.check_call(["curl", "-o", SOURCE, sys.argv[1].strip()])
    os.chmod(SOURCE, 0o600)
    with open(SOURCE, "r") as reader:
        config = yaml.safe_load(reader)

    # TODO: Helpers...
    subprocess.check_call(
        [
            "curl",
            "-L",
            "-o",
            f"{GEO_IP}.new",
            "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat",
        ],
    )
    os.rename(f"{GEO_IP}.new", GEO_IP)

    subprocess.check_call(
        [
            "curl",
            "-L",
            "-o",
            f"{GEO_SITE}.new",
            "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat",
        ]
    )
    os.rename(f"{GEO_SITE}.new", GEO_SITE)

    # override what we want:
    # https://wiki.metacubex.one/en/example/conf/
    config["profile"] = {"store-fake-ip": True}
    config["tproxy-port"] = 7892  # TODO: cleanup ports
    config["log-level"] = "warning"
    config["ipv6"] = True
    config["dns"]["ipv6"] = True
    # config["dns"]["respect-rules"] = True
    # config["dns"]["proxy-server-nameserver"] = (
    #     config["dns"]["default-nameserver"] + config["dns"]["nameserver"]
    # )
    # config["dns"]["nameserver-policy"] = {
    #     "geosite:geolocation-cn": config["dns"]["default-nameserver"]
    # }
    # config["dns"]["nameserver"] = [
    #     "https://dns.google/dns-query",
    #     "https://dns.cloudflare.com/dns-query",
    #     "https://doh.opendns.com/dns-query",
    # ]
    config["dns"]["enhanced-mode"] = "fake-ip"
    config["dns"]["fake-ip-range"] = "198.18.0.0/15"  # TODO: 10.64.0.0/10
    config["dns"]["fake-ip-filter-mode"] = "whitelist"
    config["dns"]["fake-ip-filter"] = [  # should return the fake ip
        "services.googleapis.cn",
        "geosite:geolocation-!cn",
        "+.huggingface.co",
    ]
    config["dns"]["fake-ip-reverse"] = [  # should return the real ip
        "+.xas.is",
        "+.alibaba-inc.com",
        "+.yunos-inc.com",
        "+.pool.ntp.org",
        # https://femoon.top/article/f5540f1e-fa0b-4883-9104-21ffee1e2f1b
        "steamcdn-a.akamaihd.net",
        "+.cm.steampowered.com",
        "+.steamserver.net",
    ]
    config["geodata-mode"] = True
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
    # TODO: Wider range...
    config["rules"] = list(filter(lambda r: "gvt1.com" not in r, config["rules"]))
    config["rules"] = [  # MUST prepand
        "DOMAIN-SUFFIX,ototoy.jp,ThroughJapan",
        "DOMAIN-SUFFIX,gvt1.com,Google",
    ] + config["rules"]

    # dump again
    with open(TARGET, "w") as writer:
        writer.write(yaml.dump(config))
    os.chmod(TARGET, 0o600)

    # restart mihomo, don't check
    subprocess.call(["systemctl", "restart", "mihomo.service", "dnsmasq.service"])

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
        if os.path.isfile(TARGET):
            __return__ = 0
    exit(__return__)
