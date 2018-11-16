[sql]
${sql_hosts}

[web]
${web_hosts}

[${deploymentcolor}:children]
web
sql

[${deploymentcolor}:vars]
DB_NAME=demo
DB_USER=demo
DB_PASSWORD=demo
DB_HOST=${sql_host}
DEPLOYMENTCOLOR=${deploymentcolor}

[waf]
${waf_hosts}

[waf-${deploymentcolor}:children]
waf

[waf-${deploymentcolor}:vars]
WAF_PASSWORD=${waf_password}
