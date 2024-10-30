export ENV=dev
export AZCOPY_AUTO_LOGIN_TYPE=AZCLI
export AZ_STORAGE_ACCOUNT="${ENV}kernaicluster"
export AZ_STORAGE_FILE_SHARE="${ENV}-cluster-cognition"

azcopy copy --recursive "https://$AZ_STORAGE_ACCOUNT.file.core.windows.net/$AZ_STORAGE_FILE_SHARE/minio/" "."
azcopy rm --recursive "https://$AZ_STORAGE_ACCOUNT.file.core.windows.net/$AZ_STORAGE_FILE_SHARE/caddy/*"
azcopy rm --recursive "https://$AZ_STORAGE_ACCOUNT.file.core.windows.net/$AZ_STORAGE_FILE_SHARE/kratos/*"
azcopy rm --recursive "https://$AZ_STORAGE_ACCOUNT.file.core.windows.net/$AZ_STORAGE_FILE_SHARE/oathkeeper/*"
azcopy rm --recursive "https://$AZ_STORAGE_ACCOUNT.file.core.windows.net/$AZ_STORAGE_FILE_SHARE/cognition-gateway/*"

