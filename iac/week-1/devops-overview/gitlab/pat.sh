gitlab_host="https://gitlab.devopscamp.com/"
gitlab_user="root"
gitlab_password="s2KeNZHjgHaVFLQvrWxaCbdFQEoOv2t0ubO9kEZB4U9xyLZxGG290Y1Zk1SSCQvv"

# 1. curl for the login page to get a session cookie and the sources with the auth tokens
body_header=$(curl -c cookies.txt -i "${gitlab_host}/users/sign_in" -s --insecure)
# grep the auth token for the user login for
#   not sure whether another token on the page will work, too - there are 3 of them
csrf_token=$(echo $body_header | perl -ne 'print "$1\n" if /new_user.*?authenticity_token"[[:blank:]]value="(.+?)"/' | sed -n 1p)
# 2. send login credentials with curl, using cookies and token from previous request
curl -L -b cookies.txt -c cookies.txt -i "${gitlab_host}/users/sign_in" \
  --data-raw "user%5Blogin%5D=${gitlab_user}&user%5Bpassword%5D=${gitlab_password}" \
  --data-urlencode "authenticity_token=${csrf_token}" \
  --compressed \
  --insecure 2>&1 > /dev/null

# 3. send curl GET request to personal access token page to get auth token
body_header=$(curl -H 'user-agent: curl' -b cookies.txt -i "${gitlab_host}/-/profile/personal_access_tokens" -s --insecure)

csrf_token=$(echo $body_header | perl -ne 'print "$1\n" if /csrf-token"[[:blank:]]content="(.+?)"/' | sed -n 1p)
# 4. curl POST request to send the "generate personal access token form"
#      the response will be a redirect, so we have to follow using `-L`
body_header=$(curl -L -b cookies.txt "${gitlab_host}/-/profile/personal_access_tokens" \
    --data-urlencode "authenticity_token=${csrf_token}" \
    --data 'personal_access_token[name]=golab-generated&personal_access_token[expires_at]=&personal_access_token[scopes][]=api&personal_access_token[scopes][]=read_repository&personal_access_token[scopes][]=write_repository&personal_access_token[scopes][]=sudo' --insecure)
# 5. Scrape the personal access token from the response json
personal_access_token=$(echo $body_header | perl -ne 'print "$1\n" if /new_token":"(.+?)"/' | sed -n 1p)
echo $personal_access_token