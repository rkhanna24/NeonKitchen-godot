---
type: working-report
display-name: Asset Licence Survey
status: draft
phase: phase-3
task: AS-01
source-decision: "DEC-039, #43"
---

# Asset Licence Survey

Task AS-01. Question asked: which sources of art usable in a **public** repository
exist at all, and is there enough of that terrain to run a real search against?
This is not the shortlist task — no pack is evaluated, no `content_id` coverage
is scored, no style call is made. Source granularity only: a marketplace, a
library, a jam bundle, an artist's catalogue.

## 1. Verdict, up front

Brief §6 is true and understated for the paid marketplace tier: every commercial
marketplace checked — Unity Asset Store, CraftPix, GameDev Market, Envato
Elements, Freepik, Pixabay — uses a licence that permits shipping art inside a
built game while explicitly forbidding distribution or extraction of the source
files, which is precisely what committing to a public repo does, so that whole
tier is eliminated in one motion rather than pack by pack. It is not true of the
terrain as a whole: uniformly-licensed free/CC0 libraries (Kenney.nl,
OpenClipart.org) and CC-BY libraries (Game-icons.net), plus large per-item
aggregators (OpenGameArt.org, itch.io, Poly Pizza) carrying thousands of
individually CC0/CC-BY items, survive the filter and carry real food and
character art. **There is enough surviving terrain to run a real search
against, but it is concentrated in CC0/CC-BY hobbyist-library sources rather
than the commercial packs "licensed asset packs" in DEC-039 most likely
pictured**, and DEC-039 is worth a second look with that concentration named
plainly (see §5).

## 2. Qualifying sources

A source qualifies if art committed there can sit in a public GitHub repo
without violating its licence. "Uniform" means the whole source carries one
licence; "per-item" means each upload can carry a different one and the source
itself proves nothing about any single item.

| Source | URL | Licence | Uniform? | Cost | Food/ingredient art | Character/figure art |
|---|---|---|---|---|---|---|
| Kenney.nl (mirrored at kenney-assets.itch.io) | https://kenney.nl | CC0 1.0 Universal | Yes, site-wide | Free / pay-what-you-want (paying unlocks source project files, not a different licence) | Yes — dedicated "Food Kit," 200+ items, at rough volume | Yes — "Mini Characters," "Modular Characters," "Blocky Characters," several hundred assets combined |
| OpenClipart.org | https://openclipart.org | CC0 1.0 (public domain) | Yes, mandatory on upload | Free | Present but not volume-checked beyond a tag search; clipart-style line art, not verified for food specifically | Not checked |
| Game-icons.net | https://game-icons.net | CC BY 3.0 | Yes, site-wide | Free | Yes — 133 icons tagged "food" | Not meaningfully — these are pictogram icons, not portrait/figure art |
| OpenGameArt.org | https://opengameart.org | Mixed: CC0, CC-BY 3.0, OGA-BY 3.0, CC-BY-SA 3.0 (disqualified by brief §6), GPL/LGPL | **No — per item** | Free | Large — 189 results on a "food" 2D-art search; at least one verified-CC0 item (see below) | Large — many character sprite sets, including CC-BY-SA "LPC" sets that brief §6 already rules out |
| itch.io | https://itch.io | No site licence — each creator sets terms | **No — per item.** A large CC0-tagged corpus exists (2,736 results under the "Creative Commons Zero v1.0 Universal" tag) but the site also hosts paid packs under itch's own disqualifying "General Paid Asset License" (§3) | Free items exist at "pay what you want," paid items vary | Yes, at real volume (e.g. "Free Pixel foods," 32×32) | Yes, at real volume (e.g. "KayKit — Character Pack: Adventurers," CC0) |
| Poly Pizza | https://poly.pizza | Mixed: CC0 and CC-BY per model; some listed models are re-exports of paid Unity Asset Store packages under that store's own (disqualifying) EULA | **No — per item** | Free for CC0/CC-BY entries | Yes — hamburger, pizza, hot dog, sushi, apple, fries, bread models seen in a "food" search, several attributed to known CC0 catalogues (Quaternius, Kenney) | Not checked in depth |

### Licence text and quoted clauses

**Kenney.nl** — licence text: https://creativecommons.org/publicdomain/zero/1.0/.
Kenney's own statement (https://kenney.nl/support): *"All game assets on the
asset pages are public domain licensed (CC0)."* And on the Food Kit's itch
mirror (https://kenney-assets.itch.io/food-kit): *"CC0 1.0 Universal. You're
allowed to use these game assets in any project including commercial ones."*
CC0 is a public-domain dedication; it does not merely permit redistribution of
source files, it waives the rights that would let anyone forbid it. Attribution
is optional: *"Attribution is not required, but if you choose to give credit
you can do so by mentioning 'Kenney'."* — recordable in-repo (e.g. a CREDITS
file), no submission form. **Caveat on format:** the Food Kit is 3D models
(OBJ/FBX/glTF), not flat 2D art — a preview collage image was seen
(347×500 px composite), but no individual rendered sprite was seen, so no
native 2D aspect ratio can be reported for it. Kenney also publishes flat 2D
packs (icons, UI kits) under the same CC0 terms, but none was confirmed
specifically food-related; that would be shortlist-stage work.

**OpenClipart.org** — licence text: https://creativecommons.org/publicdomain/zero/1.0/.
Site FAQ (https://openclipart.org/faq): *"We use the Creative Commons Zero 1.0
Public Domain License every time an artist uploads a piece of clipart to
Openclipart to make it clear the artist is releasing the creative work for
anyone to use for any reason, even commercially."* And: *"All artworks on
Openclipart are released in the Public Domain."* Uniform, confirmed directly
on the FAQ page rather than inferred. Attribution: none required. Cost: free.
No preview art examined for food content at this stage — existence only, not
volume-verified beyond a general tag search returning food-adjacent results.

**Game-icons.net** — licence text: https://creativecommons.org/licenses/by/3.0/legalcode.
Site statement (https://game-icons.net/about.html): *"They are provided under
the terms of the Creative Commons 3.0 BY license"* with the suggested credit
*"Icons made by {author}. Available on https://game-icons.net."* The CC BY 3.0
legal code itself (fetched directly), §3, grants the licensee the right *"to
Reproduce the Work, to incorporate the Work into one or more Collections, and
to Reproduce the Work as incorporated in the Collections,"* and *"to
Distribute and Publicly Perform the Work including as incorporated in
Collections"* — reproduction and distribution of the work itself, not only of
a compiled product containing it, is the licensed act. Attribution lands
in-repo (a CREDITS line), no submission form. Cost: free. **Caveat:** these
are monochrome SVG/PNG pictogram icons on a square canvas, recolourable at
render time — existence of food icons confirmed (133 tagged), no portrait or
figure content for the customer slot (not searched anyway, per the gate).

**OpenGameArt.org** — mixed licensing, so no single licence text URL covers the
site. The one item directly verified: "CC0 Food Icons"
(https://opengameart.org/content/cc0-food-icons) — page states *"Creative
Commons Zero (CC0)"* — licence text
https://creativecommons.org/publicdomain/zero/1.0/. Icons seen: sushi, meats,
breads, fruits, vegetables, pastries, nuts, soups, cookies, tea, peppers, at
16×16 (HomoHikka), 24×24 (bluecarrot16, Fleurman), and 32×32 — all square,
contributed by several artists under the same CC0 declaration on that one
page. For OGA-BY 3.0 items (a separate licence OGA itself defines, based on
CC-BY 3.0 with the anti-DRM clause struck), the text at
http://static.opengameart.org/OGA-BY-3.0.txt states redistribution rights in
the same terms as CC-BY 3.0 §3 quoted above, plus, on Distribution: *"You must
include a copy of, or the Uniform Resource Identifier (URI) for, this License
with every copy of the Work You Distribute."* **This is the one source in this
survey where the site itself is not a licence — every single item needs the
same per-item check just performed on "CC0 Food Icons," and the 189-result
food search returned only that one item with a licence visibly confirmed at
this pass.**

**itch.io** — no site-wide licence text exists to quote; itch.io explicitly
does not impose one (confirmed at https://itch.io/blog/929708/general-paid-asset-license,
which is a *suggested default for paid creators*, not a site policy — see §3
for why that specific licence disqualifies items that use it). The CC0-tagged
browse (https://itch.io/game-assets/assets-cc0) returns 2,736 results,
including Kenney's own catalogue mirrored there and "KayKit — Character Pack:
Adventurers" (CC0). Each item's own page is the licence text; there is no
shortcut. Attribution mechanics and cost vary per item and were not
individually re-verified beyond the two examples pulled in this survey
(Kenney's mirror, already covered above; and the food pack at §4, which failed
verification and is recorded there rather than here).

**Poly Pizza** — no site-wide licence; https://poly.pizza/search/CC0 exists as
a filter, meaning the site itself acknowledges per-item licensing by offering
it as a facet rather than a site-wide statement. A "food" search
(https://poly.pizza/search/food) turned up items credited to Quaternius and
Kenney — both known CC0 catalogues elsewhere in this survey — alongside items
linking through to paid Unity Asset Store listings, which is the disqualifying
licence from §3. No individual Poly Pizza food model's licence page was
fetched and read directly in this pass; **treat "food art exists here" as
confirmed, and "any specific model is clear to redistribute" as not
confirmed** until that model's own page is read.

## 3. Disqualified sources

Checked and eliminated by a specific clause, so the next search does not repeat
this one.

| Source | Clause that killed it | Licence text URL |
|---|---|---|
| Unity Asset Store | *"Only to the extent that assets are embedded or incorporated into a game or digital product"* — use is scoped to embedding in a built product, and the FAQ separately prohibits designing a product so that end users can extract the assets. A public source repo is exactly that extraction path. | https://assetstore.unity.com/browse/eula-faq |
| CraftPix.net (Regular licence) | *"You can NOT resell the source files (PNG, JPG, EPS, Adobe Illustrator, etc.) or slightly modified version of the art."* | https://craftpix.net/file-licenses/ |
| itch.io "General Paid Asset License" (the default many paid itch.io creators use — not itch.io itself, see §2) | *"The assets may not be: Resold, Redistributed, Shared as standalone files, Included in another asset pack or bundle, Made available for others to extract or reuse."* | https://itch.io/blog/929708/general-paid-asset-license |
| Pixabay | *"You cannot sell or distribute Content (either in digital or physical form) on a Standalone basis. Standalone means where no creative effort has been applied to the Content and it remains in substantially the same form as it exists on our website."* A source PNG committed unmodified to `assets/` is exactly that form. | https://pixabay.com/service/license-summary/ |
| GameDev Market (Pro Licence) | Quoted by a corroborating secondary source (an itch.io forum post excerpting the licence) as: *"A Licence does not allow the Purchaser to: ... Use, sell, share, transfer, give away, sublicense or redistribute the Licensed Asset or Derivate Works other than as part of the relevant Media Product; or ... Allow the user of the Media Product to extract the Licensed Asset or Derivative Works and use them outside of the relevant Media Product."* **Primary licence page could not be fetched directly — see §4.** | https://www.gamedevmarket.net/terms-conditions/#pro-licence (fetch blocked) |
| Envato Elements | Summarised consistently across Envato's own support-centre search snippets as prohibiting redistribution of items "as source files," and specifically warning that handing over a raw source file containing the item "as a separable layer or asset" breaches the licence. **Primary page could not be fetched directly — see §4.** | https://help.elements.envato.com/hc/en-us/articles/360000621803-Prohibited-Usage-of-Envato-Items (fetch blocked) |
| Freepik | Summarised consistently across Freepik's own support-centre snippets: *"The original editable file must never be redistributed... you may only publish the final product... not the source files."* **Primary page could not be fetched directly — see §4.** | https://www.freepik.com/legal/terms-of-use (fetch blocked) |
| CC-BY-SA-licensed items generally (e.g. the "LPC" — Liberated Pixel Cup — sprite sets found inside OpenGameArt.org) | Already ruled out by brief §6 itself ("viral terms against a repo that is not licensed to match"), not re-litigated here; flagged because they are a real, large fraction of what OpenGameArt.org's per-item character corpus contains. | n/a — brief's own table |

## 4. Unresolved

Three commercial sources returned HTTP 403 to the fetch tool on every attempt
at their primary licence pages (GameDev Market's `/terms-conditions` and
`/about/licences`, Envato Elements' Prohibited-Usage article, and Freepik's
`/legal` and `/legal/terms-of-use`). The clauses recorded against them in §3
come from secondary corroboration — search-engine summaries and, for GameDev
Market, a third-party forum post excerpting the licence — not from a page I
read myself. **Per the rule that an unverified licence is a refusal, none of
these three is promoted to qualifying regardless of the direction the
secondary evidence points**, and the corroborating pattern is consistent
enough (and consistent with every other commercial marketplace checked) that
they are recorded as disqualified rather than left neutral. If any of the
three turns out on a human's direct read to actually permit source
redistribution, that would be a real surprise worth flagging back — I would
not bet on it, but I did not verify it myself and say so plainly.

No qualifying source in §2 rests on an unresolved licence; every quote there
was read directly from a page the fetch tool returned successfully.

## 5. The two direct questions

**1. Is brief §6's assertion true?** Yes, and it is more severe on the paid
tier than the brief's framing suggests. The brief frames "many commercial
licences" as a caveat to check per-pack; this survey found the caveat to be
close to universal — every commercial marketplace checked (six of six) uses
the same shape of clause, embed-permitted / source-redistribution-forbidden,
which functions as a **blanket disqualification of paid marketplaces as a
class**, not a per-pack risk to screen for. That is a stronger and more
useful statement than the brief currently makes, and worth folding back in:
DEC-039 chose "licensed asset packs," and if that phrase was read as "paid
commercial packs" rather than "packs under a licence, of whatever kind," the
decision is aimed at a category that is almost entirely closed off by the
public-repo constraint. The terrain that *does* survive is real but is a
different category: CC0/CC-BY hobbyist libraries and jam-adjacent catalogues,
not storefront asset packs. Whether that is what DEC-039 meant is the human's
call, not mine, but the gap between "licensed" and "CC0" is large enough that
I'd want it named before the shortlist task starts spending effort inside the
wrong half of the terrain.

**2. Is food/item art in these sources predominantly square icons?** Yes, in
every fixed-2D-image source checked. OpenGameArt's verified "CC0 Food Icons"
ships at 16×16, 24×24, and 32×32 — square at every size offered. itch.io's
free food pack (see below, licence unverified so not a qualifying example, but
still evidence for shape) ships at 160×160 — square. Game-icons.net's food
icons render on a square SVG canvas by convention of the whole site. This is a
consistent, unbroken pattern across every 2D food source this survey touched,
which matches brief §4's own warning that "a pack of 128×128 square item icons
does not fit these shapes without being cropped or letterboxed." **One
partial exception:** sources built on 3D models rather than flat images —
Kenney's Food Kit, Poly Pizza, and the Quaternius catalogue that both surface
— are not fixed to any aspect ratio at the source, because the deliverable is
a mesh and the aspect ratio is chosen at render time. That trades the
square-icon problem for a production step (someone has to render the model at
the block's actual ratio) that is outside a licence survey's scope, but it is
a structurally different answer to the aspect-ratio question than every flat
2D source gave, and worth flagging now rather than assuming all CC0 terrain
is square.

## 6. What was searched, including negative results

Searched and read (licence pages fetched directly, not just search snippets):
Kenney.nl / kenney-assets.itch.io, OpenClipart.org, Game-icons.net,
OpenGameArt.org (site licence FAQ, OGA-BY-3.0.txt, and the "CC0 Food Icons"
item page), itch.io (the CC0 tag browse, the "General Paid Asset License"
blog post, and one specific free food pack — see negative result below),
CraftPix.net, Unity Asset Store EULA FAQ, Pixabay, Poly Pizza (site search
only, no individual model page fetched), the CC BY 3.0 legal code directly.

Searched via web search only, licence page fetch blocked (HTTP 403) on every
attempt, recorded as unresolved rather than qualifying: GameDev Market, Envato
Elements, Freepik.

**Negative result, named specifically because it demonstrates the exact risk
brief §6 warns about:** itch.io's "400+ Free Food Assets" pack
(https://2yeet.itch.io/foodassets, 160×160 px PNGs) states only *"free to
download"* and *"commercial use is allowed — no attribution required."* It
never addresses redistribution of the source files at all. Per brief §6's own
table — *"Unclear or absent licence — an unstated licence is a refusal"* —
this pack does not qualify despite reading, on its face, like exactly the
kind of free food-sprite pack this survey was hoping to find. It is recorded
here rather than in §2 or §3 because it is neither qualifying nor
affirmatively disqualified by a clause — it simply never says, which is its
own finding.

Not searched, out of time/scope for this pass, named so the next survey does
not have to rediscover the gap: Adobe Stock, Shutterstock, Vecteezy,
GraphicRiver (as distinct from Envato Elements), Sketchfab, Mixamo, TurboSquid,
CGTrader, Humble Bundle asset-pack bundles (these repackage itch.io/other
creators' own licences rather than setting one of their own, so they would
resolve to per-item itch.io-style checks anyway), and Wikimedia
Commons/photographic food sources (photographic realism is a style question
outside this task's scope, but the licence terrain there, largely CC0/PD, is
likely to qualify and is worth a pass later).

**Not searched at all, per the dispatch's explicit scope:** the customer slot
(brief §9, gated on an unanswered human decision) beyond confirming, in
passing, that character/figure art exists as a category at several qualifying
sources — no specific portrait, silhouette, full-figure, hands, or "no figure"
search was run. The city strip was checked only for whether strip-shaped or
composable city art exists as a category at the sources above (it does, at
the same sources, via the same licences), not evaluated for content.

## 7. Open questions for the human

1. **Does DEC-039's "licensed asset packs" mean paid commercial packs, or any
   packs under a licence including CC0/CC-BY?** §5.1 above is the reason this
   needs an answer before the shortlist task runs: the paid tier is nearly
   closed, and the surviving terrain is shaped differently (hobbyist/CC0
   libraries, not storefronts) than "licensed asset packs" may have implied.
2. **Is the aspect-ratio finding (§5.2) reason to reconsider sourcing 2D
   ingredient art at all**, versus sourcing 3D food models (Kenney, Poly
   Pizza, Quaternius — all CC0) and rendering them in-house at the block's
   actual ratio? That is a production-path decision, not a licence one, and
   outside this survey's authority, but it falls directly out of what the
   survey found.
3. Should the three unresolved commercial licences (GameDev Market, Envato
   Elements, Freepik) be re-checked by someone who can read the primary page
   directly, given how consistently every *other* commercial source in this
   survey pointed the same direction? Low expected payoff, but currently
   genuinely unverified rather than disqualified on a page I read myself.
4. The customer slot and the "bought vs. composed" city-strip question (brief
   §9) remain open exactly as the brief left them; this survey did not touch
   either beyond confirming that character art and city/background-adjacent
   art both exist as categories at the qualifying sources.
