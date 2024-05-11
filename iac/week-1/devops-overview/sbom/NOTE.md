https://github.com/goharbor/harbor/issues/16397
https://github.com/goharbor/harbor/issues/17622


SYFT_ATTEST_PASSWORD=password123 syft attest --key cosign.key -o spdx-json harbor.wei3.gkdevopscamp.com/example/camp-go-example@sha256:7b29758ebe6ec3b437426e13b678aed1cbaab78d2311065e045b8a7aebb78933 > image_latest_sbom_attestation.json

生成 SBOM，并扫描

syft harbor.wei3.gkdevopscamp.com/example/camp-go-example@sha256:93082bbaf6815c1269ce1346ab5c0e54324f59abf68a7b17b986ddf571dc3a3c -o spdx-json | grype


漏洞退出

grype sbom:./sbom.json --fail-on medium

私有镜像：

```
https://github.com/anchore/grype#configuration
```