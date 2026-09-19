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
