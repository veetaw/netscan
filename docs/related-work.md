# Related products and research

Reviewed 12 November 2026. Product capabilities below come from their own documentation; they are not independent accuracy benchmarks. Netscan does not copy their code or bundle their scanners.

| Project | Useful approach | Applied to Netscan |
| --- | --- | --- |
| [Fing security tools](https://help.fing.com/hc/en-us/articles/25893229155740-Assess-and-Improve-Network-Security) | Device inventory, router checks and accessible security explanations | Inventory-first navigation, actionable device findings and a guided hardening section |
| [runZero](https://help.runzero.com/docs/runzero-manual.pdf) | Multi-protocol identification and correlation of internal/external observations | Evidence from ONVIF, RTSP, greetings and imported Nmap service/CPE data; separate internal and external tests |
| [NetAlertX](https://docs.netalertx.com/FEATURES/) | Visibility into new/missing devices and network changes | Local inventory, previous observations and conservative comparison of mutually tested ports |
| [Nmap](https://nmap.org/book/man-version-detection.html) | Service/version detection rather than assuming a protocol from its port | Nmap XML import and explicit separation of port hints, protocol evidence and firmware identity |
| [IVRE](https://github.com/ivre/ivre) | Combining observations from different discovery tools | Import boundaries and provenance labels; no assumption imported observations were independently verified |
| [FACT](https://github.com/fkie-cad/FACT_core) | Firmware components and CVE correlation need their own analysis | Keep component versions separate from whole-device firmware and use bounded official applicability rules |

Native service discovery, local inventory, imports, change comparison, evidence-based protocol findings, local advisory matching and KEV/EPSS context are implemented. Continuous traffic monitoring, firmware extraction and gateway enforcement are different deployment models and are not implied by those features.

## Research that informs the design

- [Am I Infected? Lessons from Operating a Large-Scale IoT Security Diagnostic Service — USENIX Security 2025](https://www.usenix.org/conference/usenixsecurity25/presentation/sasaki): a real diagnostic/remediation service and user studies. Design implication: explain coverage and uncertainty, and give users a useful next action instead of an unexplained security score.
- [Exposed by Default — IEEE Internet of Things Journal, January 2025](https://research.vu.nl/en/publications/exposed-by-default-a-security-analysis-of-home-router-default-set-2/): analysis of consumer-router defaults and TLS/remote-management issues. Design implication: firmware CVEs alone do not cover configuration and management risks.
- [EAGLEYE — NDSS 2025](https://www.ndss-symposium.org/wp-content/uploads/2025-399-paper.pdf): analysis of hidden IoT web interfaces. Design implication: probing common ports and one standard path cannot establish the absence of other interfaces. Netscan does not run interface-fuzzing attacks against household devices.
- [MeshGuard — DSN 2026](https://arxiv.org/abs/2605.31326): MUD-based access control for Thread networks with border-router/SDN integration. A research direction for an optional gateway component, not something a phone app can enforce by itself.
- [IETF MUD, RFC 8520](https://www.rfc-editor.org/info/rfc8520/): manufacturer-described communication policies. A basis for future least-privilege recommendations when reliable profiles and enforcement exist, not an automatic trust decision.

For an eventual router-side component, useful experiments include explicit communication allowlists, verifying isolation from each segment, detecting changes in outbound destinations and local anomaly detection. Such work needs controlled evaluation, false-positive measurements and a separate privacy assessment. It is not presented as a feature of the mobile scanner.

## Baselines for practical advice

[NIST IR 8425A](https://csrc.nist.gov/pubs/ir/8425/a/final), [ETSI EN 303 645 V3.1.3](https://www.etsi.org/deliver/etsi_en/303600_303699/303645/03.01.03_60/en_303645v030103p.pdf), [ONVIF](https://www.onvif.org/profiles/whitepapers/onvif-recommendations-for-cybersecurity-best-practices-for-ip-based-physical-security-products/), [NSA home-network guidance](https://www.nsa.gov/Press-Room/News-Highlights/Article/Article/3304674/nsa-releases-best-practices-for-securing-your-home-network/), and [Canadian UPnP guidance](https://www.cyber.gc.ca/en/guidance/universal-plug-play-itsap00008).
