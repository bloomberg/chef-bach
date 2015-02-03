# Metrics schema
 
# --- !Ups

CREATE TABLE metric (
    id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(255),
    target VARCHAR(255),
    last_value DOUBLE,
    PRIMARY KEY (id)
);
CREATE UNIQUE INDEX metric_name_target_idx ON metric(name, target);

CREATE TABLE record (
    id INT NOT NULL AUTO_INCREMENT,
    metric_id INTEGER,
    timestamp BIGINT,
    prev_value DOUBLE,
    value DOUBLE,
    PRIMARY KEY (id)
);
CREATE INDEX record_metric_id ON record(metric_id);
CREATE INDEX record_timestamp ON record(timestamp);

# --- !Downs

DROP INDEX record_metric_id;
DROP INDEX record_timestamp;
DROP TABLE record;

DROP INDEX metric_name_target_index;
DROP TABLE metric;
