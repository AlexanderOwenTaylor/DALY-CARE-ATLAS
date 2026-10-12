# Medication field discovery implementation plan

Base accepted21: `6fccf10eb145ff3fa9233d19babd019f40e74346`.
Follow the paired treatment-field-discovery design. Root owns integration,
generated sites, browser acceptance, release archives and the source checkpoint.
User authorization continues; no permission is pending.

- [x] X1, Z3 and W0 critique; Y2 read-only feasibility; root fresh baseline render.
- [x] Choose in-place group order/finite links, with no new view or evidence.
- [x] Fresh independent design review; resolve concrete gaps before implementation.
- [x] One Y2 owner adds meaningful failing tests, implements only the Clinical
  template and focused tests, runs focused checks, freezes hashes/report. No
  owner build/browser/full suite/children/commit/push.
- [x] Fresh independent code review; original-owner fixes and narrow re-review.
- [x] Root applicable full checks and generated22 build from accepted21. Exact
  core/table/row parity, unchanged Home/Library/transport, bounded asset delta.
- [x] Actual desktop/phone HTTP/offline exact-field/source/coverage/Back/refresh
  journeys, keyboard/touch/disclosures and original evidence reachability.
- [x] X1/Z3/W0 opposing acceptance; original-owner fixes, final pixels and checks.
- [ ] Document and save source-only checkpoint plus public/source ZIPs and hashes;
  update the existing draft PR3, unmerged. Continue the active goal while usage
  remains. Preserve accepted21 if the next candidate is not fully accepted.

## Acceptance record

One Y2 owner implemented the finite discovery unit after six expected failing
tests. Independent source review found missing sensitivity-only publication
cues; the owner reproduced and corrected that P2 and added a regression. Z3 and
W0 then rejected the initial phone hierarchy: two preambles and generic repeated
notes delayed orders. Root approved the bounded correction in the paired spec.
The same owner consolidated neutral guidance, retained field exceptions, shortened
the introduction and tightened the native name/key links. Independent source
re-review accepted the correction. Eight discovery tests now run within the final
296 passing Node tests. Portable UI-builder checks passed nine tests with one
optional historical-fixture skip; the Treatment R separation regression passed.

Final local build is `fd84a14eb83b4abf84181eba59f9a471`, using accepted21 and the
matching historical CSV run. Every core value/type/key/order, all 147 table
descriptors and 28,802 published rows are identical. Home, Data tables, runtime and
core assets are byte-identical; only Clinical HTML grows by 6,591 bytes. Initial
Clinical assets total 3,577,732 bytes, with the unchanged 2,790,493-byte core. There
is no loading-speed improvement claim and no producer, guard or schema change.

Root ran four actual HTTP/offline Ã— desktop/phone journeys, each with 16 saved
states, exact URLs for all 11 selected pairs and native navigation to eight pairs,
both source-coverage destinations, disclosures, Back and refresh. No runtime
exception or page overflow occurred; primary field links meet 44px. Root inspected
desktop and phone pixels. Administration/order sections both fit on desktop;
phone orders moved from y1177 to about y956 and all three administration primary
links are visible on arrival. Sequential phone scrolling remains intentional.

X1 accepted exact-source meaning, protected route evidence, current coverage
asymmetry and native source browsing. W0 closed its compactness P2 on final pixels.
Z3 independently exercised 11 offline-phone states using native Enter/Tab and a
nonempty global search through field, source, coverage, Back and refresh. It
closed the layout P2. Back preserves query, route and source scroll area, but a
recreated disclosure closes and focus can return to BODY; exact link-focus
restoration is not claimed. No global accessibility, print, clinical validation
or anonymity certification follows from these bounded checks.

Local reports, initial/final renders and comparison evidence remain outside Git
under `.artifact-temp/iteration22-team/`. The final archive/source checkpoint
action occurs after this record is committed; the local iteration22 validation
file records its resulting commit, archive hashes and draft-PR status.
