## PIPELINE Work Shop
>  Study period: 2023.11 ~ 2024.01

The objective of this project is to build a DevSecOps pipeline using AWS. This involves integrating security from the early stages of development, enhancing security through the combination of open-source tools for detecting new and existing vulnerabilities. Additionally, the project aims to strengthen security through threat detection via monitoring. It proposes a DevSecOps environment that provides Infrastructure as Code (IaC) templates within the organization for easy deployment. The project advocates for the thorough integration of security at every stage of development, offering an effective strategy to address security threats.


### Architecture
---------------------------------------
![](https://velog.velcdn.com/images/ac9uaintance5_5/post/2f3373a3-7c8b-44a2-b03b-3f58f9288c90/image.png)

### Test&Deploy
---------------------------------------
1. SCA : Dependency-CHECK

2. SAST : sonarQube

3. DAST : OWASP Zed Attack Proxy



### Monitoring
---------------------------------------
1. WAF
Filtering malicious HTTP/S traffic

2. Cloud Trail 
Gather logs for AWS API call history and AWS account activities

3. Guard Duty
Detect and report malicious behavior by monitoring AWS activities, networks, etc

4. OpenSearch
Integrated collection and visualization of logs from WAF, cloudTrail, and GuardDuty are shown in the dashboard.
Based on the collected logs, a alert is sent when an abnormal log occurs.

#### OpenSearch alert setting
- WAF
	- Monitor details : per query monitor - Extraction query editor
	- Schedule : By interval - 10 minute
	- Data source : aws-waf-logs
	- Query
```
{
    "size": 100,
    "query": {
        "bool": {
            "filter": [
                {
                    "range": {
                        "timestamp": {
                            "from": "now-10m",
                            "to": null,
                            "include_lower": true,
                            "include_upper": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "term": {
                        "CHECK_BLOCK": {
                            "value": 1,
                            "boost": 1
                        }
                    }
                }
            ],
            "adjust_pure_negative": true,
            "boost": 1
        }
    },
    "_source": {
        "includes": [
            "httpRequest.clientIp",
            "httpRequest.country",
            "terminatingRuleId",
            "terminatingRuleMatchDetails.conditionType"
        ],
        "excludes": []
    },
    "aggregations": {
        "CHECK_BLOCK_count": {
            "value_count": {
                "field": "CHECK_BLOCK"
            }
        }
    }
}
```
   - Triggers Actions
```
Alerting WAF action
Monitor *{{ctx.trigger.name}}* just entered alert status.
- 10분간 BLOCK 요청 {{ctx.results.0.hits.total.value}}건 발생
- Severity: {{ctx.trigger.severity}}
- Period start: {{ctx.periodStart}}
- Period end: {{ctx.periodEnd}}
- Client IP: {{ctx.results.0.hits.hits.0._source.httpRequest.clientIp}}
- Country: {{ctx.results.0.hits.hits.0._source.httpRequest.country}}
- Rule: {{ctx.results.0.hits.hits.0._source.terminatingRuleId}}
- Condition Type: {{ctx.results.0.hits.hits.0._source.terminatingRuleMatchDetails.0.conditionType}}
```


### Terraform Instructions
---------------------------------------
First, make sure AWS CLI is installed and permissions are properly configured. After that, initialize Terraform in the Terraform Project folder.
```
cd 테라폼 코드가 존재하는 디렉토리
terraform init
```
After initialization done, changes variable values you will find in 000.tf
```
vi 000.tf
```

Verify once and if all seems well, it's time to create actual remote infratucture in AWS.
```
terraform apply
```
