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
1. WAF</br>
Filtering malicious HTTP/S traffic

2. Cloud Trail </br>
Gather logs for AWS API call history and AWS account activities

3. Guard Duty</br>
Detect and report malicious behavior by monitoring AWS activities, networks, etc

4. OpenSearch</br>
Integrated collection and visualization of logs from WAF, CloudTrail, and GuardDuty are shown in the dashboard.
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
- Cloud Trail
	- Monitor details : per query monitor - Extraction query editor
	- Schedule : By interval - 10 minute
	- Data source : cwl-
	- Query
```
{
    "query": {
        "bool": {
            "should": [
                {
                    "match": {
                        "eventName": {
                            "query": "CreateNetworkAcl",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "DeleteNetworkAcl",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "ModifyNetworkAclEntry",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "AuthorizeSecurityGroupIngress",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "RevokeSecurityGroupIngress",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "AuthorizeSecurityGroupEgress",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "RevokeSecurityGroupEgress",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "CreateSecurityGroup",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "DeleteSecurityGroup",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "CreateUser",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "UpdateUser",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "DeleteUser",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "CreateRole",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "DeleteRole",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "CreatePolicy",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "DeletePolicy",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "CreatePolicyVersion",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "DeletePolicyVersion",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "CreateAccessKey",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "CreateFunction",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "UpdateFunctionCode",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "UpdateFunctionConfiguration",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "PutBucketAcl",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "PutBucketPolicy",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "PutBucketCors",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "PutParameter",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "match": {
                        "eventName": {
                            "query": "DeleteParameter",
                            "operator": "OR",
                            "prefix_length": 0,
                            "max_expansions": 50,
                            "fuzzy_transpositions": true,
                            "lenient": false,
                            "zero_terms_query": "NONE",
                            "auto_generate_synonyms_phrase_query": true,
                            "boost": 1
                        }
                    }
                }
            ],
            "adjust_pure_negative": true,
            "boost": 1
        }
    }
}
```
- Triggers : ctl-AccessKey
```
Monitor *{{ctx.trigger.name}}* just entered alert status. 
  - Severity: {{ctx.trigger.severity}}
  - Period start: {{ctx.periodStart}}
  - Period end: {{ctx.periodEnd}}
  - Event Name: AccessKey Created
```

- Guard Duty
	- Monitor details : per query monitor - Extraction query editor
	- Schedule : By interval - 15 minute
	- Data source : guardduty-logs
	- Query
```
{
    "query": {
        "bool": {
            "filter": [
                {
                    "range": {
                        "severity": {
                            "from": 8,
                            "to": null,
                            "include_lower": true,
                            "include_upper": true,
                            "boost": 1
                        }
                    }
                },
                {
                    "range": {
                        "createdAt": {
                            "from": "now-15m",
                            "to": null,
                            "include_lower": true,
                            "include_upper": true,
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
            "severity",
            "type",
            "createdAt"
        ],
        "excludes": []
    }
}
```
```
Monitor *guard-duty* alert just entered alert status.
  - GuardDuty Severity: {{ctx.results.0.hits.hits.0._source.severity}}
  - Type: {{ctx.results.0.hits.hits.0._source.type}}
  - CreatedAt : {{ctx.results.0.hits.hits.0._source.createdAt}}
  - Period start: {{ctx.periodStart}}
  - Period end: {{ctx.periodEnd}}
```

### Terraform Instructions
---------------------------------------
First, make sure AWS CLI is installed and permissions are properly configured. After that, initialize Terraform in the Terraform Project folder.
```
cd terraform
terraform init
```
It's time to see/verify what resources this will create.
```
terraform plan
```

Verify once and if all seems well, it's time to create actual remote infratucture in AWS.
```
terraform apply
```
