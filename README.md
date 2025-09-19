# 3과제 배포
## ECR
- product
```
FROM public.ecr.aws/amazonlinux/amazonlinux:2023

WORKDIR /app

COPY product .

RUN yum install -y shadow-utils
RUN chmod +x ./product

CMD ["./product"]
```

- stress

```
FROM public.ecr.aws/amazonlinux/amazonlinux:2023

WORKDIR /app

COPY stress .

RUN yum install -y shadow-utils
RUN chmod +x ./stress

CMD ["./stress"]
```

- user

```
FROM public.ecr.aws/amazonlinux/amazonlinux:2023

WORKDIR /app

COPY user .

RUN yum install -y shadow-utils
RUN chmod +x ./user

CMD ["./user"]
```

## Database
- 삽입 명령어

```
CREATE TABLE user (
    id               VARCHAR(255)    NOT NULL,   
    username         VARCHAR(255)    NOT NULL,
    email            VARCHAR(255)    NOT NULL,
    status_message   VARCHAR(255)    NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_username (username)
);
```
- user 대량 삽입

```
source load_user.dump
```

- 조회 키 : email → MySQL Index 생성

```
CREATE INDEX user_email ON user (email);
```
## ECS
- `Container Insights` 활성화
- t3.medium `2,048 단위(2vCPU), 3,827MiB(3.737GB)`, t3 small 
- user `0.7 1.4` product `0.5 1.0` stress `0.6 1.2 `
- 상태확인 : `CMD-SHELL, curl -f http://localhost:8080/healthcheck || exit 1`
## Cloudfront
- user 캐시 정책 : `CachingDisabled,` `All viewer`
- product 캐시 정책 : `id만 허용만 정책`, `All viewer`
- stress 캐시 정책 : `CachingDisabled,` `All viewer`
## WAF
- URI path : `/v1/user`
- HTTP method : `POST`
- Body 검사를 통해 `email validation`
- email regex : `^[^@]+@[^@]+\.[^@]+$`
## Dashboard
```
{
    "widgets": [
        {
            "type": "metric",
            "x": 12,
            "y": 6,
            "width": 6,
            "height": 6,
            "properties": {
                "region": "ap-northeast-2",
                "title": "Top 서비스 per CPU 사용률",
                "legend": {
                    "position": "right"
                },
                "timezone": "LOCAL",
                "metrics": [
                    [ { "expression": "SELECT AVG(CPUUtilization) FROM SCHEMA(\"AWS/ECS\", ClusterName, ServiceName)  GROUP BY ClusterName, ServiceName ORDER BY AVG() DESC LIMIT 10" } ]
                ],
                "liveData": false,
                "period": 60,
                "annotations": {
                    "horizontal": [
                        {
                            "value": 80,
                            "label": "High Utilization >="
                        }
                    ]
                },
                "yAxis": {
                    "left": {
                        "min": 0,
                        "showUnits": false
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 6,
            "height": 6,
            "properties": {
                "metrics": [
                    [ { "expression": "SELECT MAX(TaskCpuUtilization) FROM SCHEMA(\"ECS/ContainerInsights\", ClusterName, TaskDefinitionFamily, TaskId)  GROUP BY ClusterName, TaskDefinitionFamily, TaskId ORDER BY MAX() DESC LIMIT 10", "region": "ap-northeast-2", "period": 60 } ]
                ],
                "region": "ap-northeast-2",
                "title": "Top 작업 per CPU 사용률",
                "legend": {
                    "position": "right"
                },
                "timezone": "LOCAL",
                "liveData": false,
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "showUnits": false
                    }
                },
                "view": "timeSeries",
                "stacked": false,
                "stat": "Average"
            }
        },
        {
            "type": "metric",
            "x": 6,
            "y": 6,
            "width": 6,
            "height": 6,
            "properties": {
                "region": "ap-northeast-2",
                "title": "Top 컨테이너 per CPU 사용률",
                "legend": {
                    "position": "right"
                },
                "timezone": "LOCAL",
                "metrics": [
                    [ { "expression": "SELECT MAX(ContainerCpuUtilization) FROM SCHEMA(\"ECS/ContainerInsights\", ClusterName, TaskDefinitionFamily, TaskId, ContainerName)  GROUP BY ClusterName, TaskDefinitionFamily, TaskId, ContainerName ORDER BY MAX() DESC LIMIT 10" } ]
                ],
                "liveData": false,
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "showUnits": false
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 6,
            "height": 6,
            "properties": {
                "period": 60,
                "metrics": [
                    [ "AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "app/user/8e6b5cfc3d672fdf", { "label": "user", "visible": true, "region": "ap-northeast-2" } ],
                    [ "...", "app/product/6fa8c98f46a36b2f", { "label": "product", "visible": true, "region": "ap-northeast-2" } ],
                    [ "...", "app/stress/6216db327269dd0d", { "label": "stress", "visible": true, "region": "ap-northeast-2" } ]
                ],
                "region": "ap-northeast-2",
                "stat": "Average",
                "title": "대상 응답 시간",
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                },
                "view": "timeSeries",
                "stacked": false
            }
        },
        {
            "type": "metric",
            "x": 6,
            "y": 0,
            "width": 6,
            "height": 6,
            "properties": {
                "period": 60,
                "metrics": [
                    [ "AWS/ApplicationELB", "RequestCount", "LoadBalancer", "app/user/8e6b5cfc3d672fdf", { "label": "user", "visible": true, "region": "ap-northeast-2" } ],
                    [ "...", "app/product/6fa8c98f46a36b2f", { "label": "product", "visible": true, "region": "ap-northeast-2" } ],
                    [ "...", "app/stress/6216db327269dd0d", { "label": "stress", "visible": true, "region": "ap-northeast-2" } ]
                ],
                "region": "ap-northeast-2",
                "stat": "Sum",
                "title": "요청",
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                },
                "view": "timeSeries",
                "stacked": false
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 6,
            "height": 6,
            "properties": {
                "period": 60,
                "metrics": [
                    [ "AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "app/user/8e6b5cfc3d672fdf", { "label": "user", "visible": true, "region": "ap-northeast-2" } ],
                    [ "...", "app/product/6fa8c98f46a36b2f", { "label": "product", "visible": true, "region": "ap-northeast-2" } ],
                    [ "...", "app/stress/6216db327269dd0d", { "label": "stress", "visible": true, "region": "ap-northeast-2" } ]
                ],
                "region": "ap-northeast-2",
                "stat": "Sum",
                "title": "5XXs error",
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                },
                "view": "timeSeries",
                "stacked": false
            }
        },
        {
            "type": "metric",
            "x": 18,
            "y": 0,
            "width": 6,
            "height": 6,
            "properties": {
                "period": 60,
                "metrics": [
                    [ "AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", "app/user/8e6b5cfc3d672fdf", { "label": "user", "visible": true, "region": "ap-northeast-2" } ],
                    [ "...", "app/product/6fa8c98f46a36b2f", { "label": "product", "visible": true, "region": "ap-northeast-2" } ],
                    [ "...", "app/stress/6216db327269dd0d", { "label": "stress", "visible": true, "region": "ap-northeast-2" } ]
                ],
                "region": "ap-northeast-2",
                "stat": "Sum",
                "title": "4XXs error",
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                },
                "view": "timeSeries",
                "stacked": false
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 12,
            "width": 6,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "apdev-rds-instance", { "label": "apdev-rds-instance", "region": "ap-northeast-2" } ]
                ],
                "period": 60,
                "region": "ap-northeast-2",
                "stat": "Average",
                "title": "RDS-CPUUtilization",
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                },
                "view": "timeSeries",
                "stacked": false
            }
        },
        {
            "type": "metric",
            "x": 6,
            "y": 12,
            "width": 6,
            "height": 6,
            "properties": {
                "title": "DynamoDB-쓰기 사용량(평균 단위/초)",
                "view": "timeSeries",
                "stacked": false,
                "region": "ap-northeast-2",
                "stat": "Average",
                "period": 60,
                "yAxis": {
                    "left": {
                        "showUnits": false
                    }
                },
                "metrics": [
                    [ "AWS/DynamoDB", "ConsumedWriteCapacityUnits", "TableName", "product", { "stat": "Sum", "id": "m1", "visible": false, "region": "ap-northeast-2" } ],
                    [ { "expression": "m1/PERIOD(m1)", "label": "사용됨", "id": "e1", "color": "#0073BB", "region": "ap-northeast-2" } ]
                ]
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 12,
            "width": 6,
            "height": 6,
            "properties": {
                "title": "DynamoDB-읽기 사용량(평균 단위/초)",
                "view": "timeSeries",
                "stacked": false,
                "region": "ap-northeast-2",
                "stat": "Average",
                "period": 60,
                "yAxis": {
                    "left": {
                        "showUnits": false
                    }
                },
                "metrics": [
                    [ "AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", "product", { "stat": "Sum", "id": "m1", "visible": false, "region": "ap-northeast-2" } ],
                    [ { "expression": "m1/PERIOD(m1)", "label": "사용됨", "id": "e1", "color": "#0073BB", "region": "ap-northeast-2" } ]
                ]
            }
        },
        {
            "type": "log",
            "x": 0,
            "y": 24,
            "width": 24,
            "height": 6,
            "properties": {
                "query": "SOURCE '/ecs/product' | SOURCE '/ecs/stress' | SOURCE '/ecs/user' | fields @timestamp, @message, @logStream, @log\n| filter @message not like /healthcheck/ \n| filter @message like / 5[0-9]{2} /\n| sort @timestamp desc\n| limit 100",
                "region": "ap-northeast-2",
                "stacked": false,
                "view": "table",
                "title": "5xx Logs"
            }
        },
        {
            "type": "log",
            "x": 0,
            "y": 18,
            "width": 24,
            "height": 6,
            "properties": {
                "query": "SOURCE '/ecs/product' | SOURCE '/ecs/stress' | SOURCE '/ecs/user' | fields @timestamp, @message, @logStream, @log\n| filter @message not like /healthcheck/ \n| sort @timestamp desc\n| limit 100",
                "region": "ap-northeast-2",
                "stacked": false,
                "view": "table",
                "title": "App Logs"
            }
        },
        {
            "type": "log",
            "x": 0,
            "y": 30,
            "width": 24,
            "height": 6,
            "properties": {
                "query": "SOURCE '/ecs/product' | SOURCE '/ecs/stress' | SOURCE '/ecs/user' | fields @timestamp, @message, @logStream, @log\n| filter @message not like /healthcheck/ \n| filter @message like / 4[0-9]{2} /\n| sort @timestamp desc\n| limit 100",
                "region": "ap-northeast-2",
                "stacked": false,
                "view": "table",
                "title": "4xx Logs"
            }
        }
    ]
}
```
## Athena
1. ALB Logs

```
CREATE EXTERNAL TABLE IF NOT EXISTS product (
            type string,
            time string,
            elb string,
            client_ip string,
            client_port int,
            target_ip string,
            target_port int,
            request_processing_time double,
            target_processing_time double,
            response_processing_time double,
            elb_status_code int,
            target_status_code string,
            received_bytes bigint,
            sent_bytes bigint,
            request_verb string,
            request_url string,
            request_proto string,
            user_agent string,
            ssl_cipher string,
            ssl_protocol string,
            target_group_arn string,
            trace_id string,
            domain_name string,
            chosen_cert_arn string,
            matched_rule_priority string,
            request_creation_time string,
            actions_executed string,
            redirect_url string,
            lambda_error_reason string,
            target_port_list string,
            target_status_code_list string,
            classification string,
            classification_reason string,
            conn_trace_id string
            )
            PARTITIONED BY
            (
             day STRING
            )
            ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.RegexSerDe'
            WITH SERDEPROPERTIES (
            'serialization.format' = '1',
            'input.regex' = 
        '([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*):([0-9]*) ([^ ]*)[:-]([0-9]*) ([-.0-9]*) ([-.0-9]*) ([-.0-9]*) (|[-0-9]*) (-|[-0-9]*) ([-0-9]*) ([-0-9]*) \"([^ ]*) (.*) (- |[^ ]*)\" \"([^\"]*)\" ([A-Z0-9-_]+) ([A-Za-z0-9.-]*) ([^ ]*) \"([^\"]*)\" \"([^\"]*)\" \"([^\"]*)\" ([-.0-9]*) ([^ ]*) \"([^\"]*)\" \"([^\"]*)\" \"([^ ]*)\" \"([^\\s]+?)\" \"([^\\s]+)\" \"([^ ]*)\" \"([^ ]*)\" ?([^ ]*)?'
            )
            LOCATION 's3://3rd-practice-logs-arco/alb/product/AWSLogs/073813292468/elasticloadbalancing/ap-northeast-2/'
            TBLPROPERTIES
            (
             "projection.enabled" = "true",
             "projection.day.type" = "date",
             "projection.day.range" = "2022/01/01,NOW",
             "projection.day.format" = "yyyy/MM/dd",
             "projection.day.interval" = "1",
             "projection.day.interval.unit" = "DAYS",
             "storage.location.template" = "s3://3rd-practice-logs-arco/alb/product/AWSLogs/073813292468/elasticloadbalancing/ap-northeast-2/${day}"
            )
```
2. CloudFront Logs

```
CREATE EXTERNAL TABLE IF NOT EXISTS cloudfront_standard_logs (
  `date` DATE,
  time STRING,
  x_edge_location STRING,
  sc_bytes BIGINT,
  c_ip STRING,
  cs_method STRING,
  cs_host STRING,
  cs_uri_stem STRING,
  sc_status INT,
  cs_referrer STRING,
  cs_user_agent STRING,
  cs_uri_query STRING,
  cs_cookie STRING,
  x_edge_result_type STRING,
  x_edge_request_id STRING,
  x_host_header STRING,
  cs_protocol STRING,
  cs_bytes BIGINT,
  time_taken FLOAT,
  x_forwarded_for STRING,
  ssl_protocol STRING,
  ssl_cipher STRING,
  x_edge_response_result_type STRING,
  cs_protocol_version STRING,
  fle_status STRING,
  fle_encrypted_fields INT,
  c_port INT,
  time_to_first_byte FLOAT,
  x_edge_detailed_result_type STRING,
  sc_content_type STRING,
  sc_content_len BIGINT,
  sc_range_start BIGINT,
  sc_range_end BIGINT
)
ROW FORMAT DELIMITED 
FIELDS TERMINATED BY '\t'
LOCATION 's3://3rd-practice-logs-arco/cloudfront/'
TBLPROPERTIES ( 'skip.header.line.count'='2' )
```
