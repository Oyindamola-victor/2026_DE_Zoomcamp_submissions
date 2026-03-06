-- Creating external table referring to gcs path
CREATE OR REPLACE EXTERNAL TABLE `your_project_id.your_dataset.external_yellow_tripdata_2024`
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://your_bucket_name/yellow_tripdata_2024-*.parquet']
);

-- Question 1: How many rows are there in the dataset? 
SELECT COUNT(*) FROM `your_project_id.your_dataset.external_yellow_tripdata_2024`
-- Answer: 20,332,093

-- QUESTION 2: Write a query to count the distinct number of PULocationIDs for the entire dataset on both the tables.
-- What is the estimated amount of data that will be read when this query is executed on the External Table and the Table?
--Answer: 0 MB for the External Table and 155.12 MB for the Materialized Table
-- For the external table
SELECT COUNT(DISTINCT(PULocationID)) FROM `your_project_id.your_dataset.external_yellow_tripdata_2024`;

-- For the normal table
SELECT COUNT(DISTINCT(PULocationID)) FROM `your_project_id.your_dataset.yellow_tripdata_2024_non_partitioned`;


--QUESTION 3: Write a query to retrieve the PULocationID from the table (not the external table) in BigQuery. Now write a query to retrieve the PULocationID and DOLocationID on the same table.
-- Why are the estimated number of Bytes different?
--ANSWER:

-- BigQuery is a columnar database, and it only scans the specific columns requested in the query. Querying two columns (PULocationID, DOLocationID) requires reading more data than querying one column (PULocationID), leading to a higher estimated number of bytes processed.

-- QUESTION 4: How many records have a fare_amount of 0?
SELECT COUNT(*) FROM `your_project_id.your_dataset.yellow_tripdata_2024_non_partitioned` WHERE fare_amount = 0;
-- Answer: 8333

-- QUESTION 5: What is the best strategy to make an optimized table in Big Query if your query will always filter based on tpep_dropoff_datetime and order the results by VendorID (Create a new table with this strategy)
--ANSWER: Partition by tpep_dropoff_datetime and Cluster on VendorID
CREATE OR REPLACE TABLE `your_project_id.your_dataset.yellow_tripdata_2024_partitioned`
PARTITION BY DATE(tpep_dropoff_datetime)
CLUSTER BY VendorID
AS SELECT * FROM `your_project_id.your_dataset.external_yellow_tripdata_2024`;

-- QUESTION 6: Write a query to retrieve the distinct VendorIDs between tpep_dropoff_datetime 2024-03-01 and 2024-03-15 (inclusive)
-- Use the materialized table you created earlier in your from clause and note the estimated bytes. 
-- Now change the table in the from clause to the partitioned table you created for question 5 and note the estimated bytes processed. What are these values?

-- ANSWER: ESTIMATED BYTES: 310.24 MB for the materialized table and 26.84 MB MB for the partitioned table

--QUESTION 7: Where is the data stored in the External Table you created?
--ANSWER: GCP Bucket

-- QUESTION 8: It is best practice in Big Query to always cluster your data:
--ANSWER: FALSE
