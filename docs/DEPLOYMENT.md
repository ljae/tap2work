# tap2work development site

- Repository: https://github.com/ljae/tap2work
- Domain: tap2.work (Namecheap BasicDNS)
- Public review: GitHub Pages; `.github/workflows/pages.yml` checks and deploys `main`.
- Public Flutter: `https://tap2.work/`, fixed sample data, operational writes disabled.
- Feedback: explicit public GitHub issue submission; CEO is contacted by the user.

## DNS

The deployed public app is served directly at `https://tap2.work/`. The Pages artifact is built from Flutter at the root; it no longer includes the former development journal or project-state files. `/app/` redirects to `/` for older links. The app remains a read-only sample build.

| Type | Host | Value |
| --- | --- | --- |
| A | @ | 185.199.108.153 |
| A | @ | 185.199.109.153 |
| A | @ | 185.199.110.153 |
| A | @ | 185.199.111.153 |
| CNAME | www | ljae.github.io |

Replaced Namecheap's default apex URL redirect and www parking record. Existing email records and nameservers were retained. These are [GitHub's documented DNS targets](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site).

## HTTPS commissioning

At the 2026-09-19 verification, HTTP served the renamed site, authoritative DNS returned all four A records, and GitHub reported both apex and www DNS valid. GitHub had not issued the new certificate yet; enabling `https_enforced` returned “The certificate does not exist yet”. Do not claim HTTPS ready until a normal certificate-validating request succeeds.

After GitHub issues the certificate, enable HTTPS in the repository's Pages settings, or run:

```sh
gh api repos/ljae/tap2work/pages
gh api --method PUT repos/ljae/tap2work/pages -F https_enforced=true
curl -I https://tap2.work/
```

The account-level Pages site uses another custom domain. A project without its own Pages custom domain can inherit that hostname, so use tap2.work for this project's canonical public address. Repository renaming does not itself configure DNS.

## Local verification

`npm run build:site` creates `_site/` from a separate Flutter build and fresh code-generated sample state. It never publishes `.local/` or the local console's write APIs. Use `npm run build:app` for the localhost shared demo instead.

Initial publish: workflow 35436895916. Renamed publish: workflow 35437081320 (both passed). Native app builds were not run for this change.

## Restaurant dashboard release

Feature commit `0832ba0` was merged into `main` as `fd1ccb9`. [Workflow 35440364916](https://github.com/ljae/tap2work/actions/runs/35440364916) passed all checks, built the public Flutter app, and deployed Pages. Live HTTP checks confirmed project revision 12 and the new dashboard in owner/crew sample responses; financial fields are excluded for crew. This deployment record is saved in revision 13.

HTTPS remained unavailable at this verification: certificate hostname mismatch, and the Pages API rejected HTTPS enforcement because the certificate does not exist yet. HTTP was verified without bypassing TLS validation.

## Restaurant layout and logo release

Commit `a2c8d59` on `main` adds configurable restaurant tables/equipment and the user-supplied `tap2work.png`. [Workflow 35443929355](https://github.com/ljae/tap2work/actions/runs/35443929355) passed checks, Flutter analysis/tests, the public web build and Pages deployment. Live HTTP verification confirmed project revision 14, six sample tables with 24 seats, portal logo markup and byte-identical portal/Flutter logo assets. Public layout drafts remain unsaved. This verification is recorded in project revision 15.

HTTPS still failed hostname validation (`curl` exit 60); Pages reported `https_enforced=false`. Native builds and physical-device testing were not performed.

## Doodle logo release

Commit `3190f56` replaces the logo with the newly generated comforting blob characters and adjusts header sizing. [Workflow 35444980003](https://github.com/ljae/tap2work/actions/runs/35444980003) passed all checks, tests, the public web build and Pages deployment. Live HTTP verification confirmed revision 16 and byte-identical new logo assets at both `/tap2work.png` and `/app/assets/assets/branding/tap2work.png`. This result is recorded in project revision 17. HTTPS still failed hostname validation (`curl` exit 60); native builds and physical-device testing were not performed.

## CEO 데모 · 팀원 간 확인 동기화 (터널)

공개 사이트는 정적이므로 그 자체로는 팀원 간 확인 상태를 공유하지 못합니다. 데모 중에는 사장님 Mac에서 로컬 콘솔을 켜고 터널로 노출해, 같은 공개 앱을 여는 모든 팀원이 한 서버의 상태를 공유하게 합니다.

1. `npm run build:app` 후 `npm run dev:shared` (`DEMO_PUBLIC_ORIGIN`에 tap2.work 출처를 허용한 콘솔, 3100 포트, 루프백 바인딩 유지).
2. 다른 터미널에서 `npm run tunnel` (`cloudflared tunnel --url http://localhost:3100`). 출력되는 `https://<이름>.trycloudflare.com` 주소를 복사합니다. 빠른 터널 주소는 실행할 때마다 바뀝니다.
3. 팀원에게 `https://tap2.work/?api=https://<이름>.trycloudflare.com` 링크를 보냅니다. 브라우저가 주소를 기억하므로 이후에는 `https://tap2.work/`만 열어도 연결됩니다. 연결 해제는 `?api=off`.
4. 앱 상단 띠에 `공유 데모 서버 연결 · <호스트>`가 보이면 한 명이 활동을 확인할 때 다른 팀원 화면에 5초 안에 같은 확인자·시각이 표시됩니다.

경계: 터널은 `/api/operations`만 외부에 열고, 콘솔 화면과 결정 기록 API(`/api/project`, `/api/decisions`)는 계속 로컬에서만 응답합니다. 데모 역할 선택은 여전히 인증이 아니며, 링크를 아는 누구나 샘플 매장 상태를 바꿀 수 있습니다. 실제 직원 정보는 넣지 마세요. 터널을 닫으면 공개 앱은 연결 실패 배너를 보이며, `?api=off`로 다시 읽기 전용 미리보기로 돌아갑니다.

## 미니멀 브랜드와 도메인 루트 앱 · 2026-09-24

Commit `838065d` applied the user-provided `logo_tap2work.png`, a warm white/navy/coral palette, and SF-style monochrome icons, and serves the Flutter app directly at `https://tap2.work/`. The app logo was resized from 6.9 MB to about 0.5 MB. The build no longer publishes the development journal or project decision/history files; `/app/` redirects old links to the root app. [Workflow 35948378586](https://github.com/ljae/tap2work/actions/runs/35948378586) passed all checks, 61 Flutter tests, the web build, and Pages deployment. Live HTTP checks confirmed root `200`, legacy `/app/` redirect page `200`, and synthetic review sample `200`. Native builds and physical-device checks were not performed. This result is recorded in project revision 36.

## Supabase workspace deployment · 2026-09-24

The root Flutter app now receives only `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` from GitHub repository Variables. Local builds use the same allowlist from `.env`. `npm run backend:deploy` applies the SQL migration and deploys the Auth-verified `operations` Edge Function with a management token. See [SUPABASE.md](SUPABASE.md) for configuration, access controls and current scope. Auth confirmation redirects use `https://tap2.work/`. The Edge Function uses Supabase's server-provided service role key; no service key is included in Pages.

Code commit `5f5fd73` deployed successfully via [Actions 35950908223](https://github.com/ljae/tap2work/actions/runs/35950908223). CI passed JavaScript checks, 41 Node tests, Flutter analysis, 64 Flutter tests and the public build. Supabase live checks used two temporary users to verify isolation, persisted order completion, stale revision rejection and denied raw state access; both users and their workspaces were removed. Native builds and email delivery remain unverified.

## Menu TAPs and staffing calendar release - 2026-09-24

Commit `74bcc3f` deployed through [Actions 35978317770](https://github.com/ljae/tap2work/actions/runs/35978317770). The Supabase `operations` function was also redeployed from this source; no schema migration was required. CI passed 44 Node tests, 66 Flutter tests, Flutter analysis, JavaScript checks and the public web build.

Live HTTPS checks confirmed the circular logo/favicon byte-for-byte, menu-line TAP samples, three default staffing slots, new calendar/manual code, removal of the five-minute plan and the `/app/` redirect. Configured private credentials were absent from deployed JavaScript. A temporary Auth account verified persisted menu/group completion, manual media links, staffing assignments, revision conflicts and rejection of unauthenticated requests, then was deleted with its workspace. Native builds, physical-device interaction and email delivery were not tested.

## Prepared-item workflow release · 2026-09-24

Commit `f0a223c` separated advance preparation from each customer menu TAP. A configurable prepared-item ledger now debits once when menu cooking starts, credits actual completed prep output once, and creates one open prep TAP when the balance reaches its store-configured shortage point. The header is taller, with a larger circular logo and wordmark. The Supabase `operations` Edge Function was redeployed from the same source without a schema migration.

[Actions 35981038854](https://github.com/ljae/tap2work/actions/runs/35981038854) passed JavaScript checks, 48 Node tests, Flutter analysis, 69 Flutter tests and the public build/deploy. Live HTTPS root returned 200; the deployed app bundle and favicon matched the local public build byte-for-byte. The live review sample contained one prepared item, one generated prep TAP and three Small TAPs per menu order. The function rejected an unauthenticated request with 401. Authenticated live prep mutations, native builds and physical-device interaction were not tested.

## Order progress and staffing calendar release · 2026-09-24

Commit `445a945` deployed the two-section Todo board with gradual TAP progress color, order-specific packaging and handoff Small TAPs, delivery platform and request display, a 30-minute weekly staff grid with repeat assignment, four bottom destinations, owner-only labor view in Status, and materials status below the Place map. The Supabase `operations` function was redeployed from the same source without a schema migration.

[Actions 36011221805](https://github.com/ljae/tap2work/actions/runs/36011221805) passed JavaScript checks, 51 Node tests, Flutter analysis, 71 Flutter tests and Pages deployment. The live HTTPS root returned 200 and its app bundle matched the local public build byte-for-byte. The public sample contained all three order channels, a named delivery platform and no active standalone packing TAP. The function rejected an unauthenticated request with 401. Authenticated live mutations, native builds and physical-device interaction were not tested.
