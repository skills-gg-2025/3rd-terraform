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
- 한 눈에 지표를 볼 수 있도록 Dashboard 구성
- EC2 지표 : CPUUtilization
- ALB 지표 : RequestCount, TargetResponseTime, HTTPCode_Target_5XX_Count
- RDS 지표 : CPUUtilization
- DynamoDB 지표 : ConsumedReadCapacityUnits, ConsumedWriteCapacityUnits
```
fields @timestamp, @message, @logStream, @log
| filter @message not like /healthcheck/ 
| filter @message like / 2[0-9]{2} /
| sort @timestamp desc
| limit 100
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
