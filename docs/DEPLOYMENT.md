# tap2work development site

- Repository: https://github.com/ljae/tap2work
- Domain: tap2.work (Namecheap BasicDNS)
- Public review: GitHub Pages; `.github/workflows/pages.yml` checks and deploys `main`.
- Public Flutter: `/app/`, fixed sample data, operational writes disabled.
- Feedback: explicit public GitHub issue submission; CEO is contacted by the user.

## DNS

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
3. 팀원에게 `http://tap2.work/app/?api=https://<이름>.trycloudflare.com` 링크를 보냅니다. 브라우저가 주소를 기억하므로 이후에는 `http://tap2.work/app/`만 열어도 연결됩니다. 연결 해제는 `?api=off`.
4. 앱 상단 띠에 `공유 데모 서버 연결 · <호스트>`가 보이면 한 명이 활동을 확인할 때 다른 팀원 화면에 5초 안에 같은 확인자·시각이 표시됩니다.

경계: 터널은 `/api/operations`만 외부에 열고, 콘솔 화면과 결정 기록 API(`/api/project`, `/api/decisions`)는 계속 로컬에서만 응답합니다. 데모 역할 선택은 여전히 인증이 아니며, 링크를 아는 누구나 샘플 매장 상태를 바꿀 수 있습니다. 실제 직원 정보는 넣지 마세요. 터널을 닫으면 공개 앱은 연결 실패 배너를 보이며, `?api=off`로 다시 읽기 전용 미리보기로 돌아갑니다.
