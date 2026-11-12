# Reviewed advisory matching

Reviewed on **12 November 2026**. Rules execute locally and use confirmed product details, without an LLM. They assess applicability of a named advisory; they do not demonstrate exploitability or certify that an updated device has no other vulnerabilities.

| Product | Rule coverage | Sources |
| --- | --- | --- |
| TP-Link Archer AX21, US V1.2 / V2 / V3 | Full numeric firmware and build date compared with `1.1.4 Build 20230219`. Region, supported revision and confirmed details are required. Other regions, revisions and unrecognised formats remain unresolved. | [TP-Link advisory](https://www.tp-link.com/us/support/faq/3643/), [CVE/NVD range](https://nvd.nist.gov/vuln/detail/CVE-2023-1389) |
| ASUS RT-AX55 | Exact affected release `3.0.0.4.386_50460` from TWCERT. The rule does not extrapolate to unlisted intermediate releases. Advisory fix: `3.0.0.4.386_51948`; check ASUS for later supported firmware. | [TWCERT advisory](https://www.twcert.org.tw/tw/cp-132-7354-4e654-1.html) |
| Hikvision DS-2CD2122F-I / DS-2CD2022F-I | Selected models from the documented DS-2CD2xx2F-I family. Requires both version `V5.2.0`–`V5.4.0` and valid build date `140721`–`160530`. OEM variants and other suffixes are excluded. | [CISA ICSA-17-124-01](https://www.cisa.gov/news-events/ics-advisories/icsa-17-124-01), [CVE/NVD](https://nvd.nist.gov/vuln/detail/CVE-2017-7921) |

“Outside known range” means this rule did not establish applicability. It does not mean the product is safe or that every firmware outside the range is patched. Where the source does not restrict a hardware revision or region, the rule does not invent a restriction or assert that the revision was measured.

NVD keyword results are shown separately as **candidates**. A similar product name, MAC vendor, open port or service banner cannot create a confirmed firmware match. Keep service component versions separate from device firmware.

To add a rule, provide an official vendor/CNA/CERT advisory, exact product and hardware/region applicability, affected bounds, vendor remediation URL, and tests for affected, boundary, malformed, unknown and OEM cases. Review source changes before extending a range. Do not infer a fixed release from a third-party search snippet.

## Exploitation context

On request, Netscan downloads the complete [CISA KEV catalog](https://github.com/cisagov/kev-data) and asks [FIRST EPSS](https://www.first.org/epss/) for the displayed CVE IDs. Feed failures remain unknown; absence of an EPSS row is not a zero probability. Feed dates are shown.

KEV records observed exploitation and should raise the priority of an **applicable** vulnerability. EPSS estimates exploitation activity over the next 30 days across its population, not a user-specific probability of compromise. Neither establishes that the scanned product is affected. See [FIRST’s explanation and limitations](https://www.first.org/epss/faq).
