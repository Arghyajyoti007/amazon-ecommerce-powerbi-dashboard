from pyspark.sql.functions import to_date, date_format, col
from awsglue.dynamicframe import DynamicFrame

# Convert and partition by snapshot_day
DerivedColumn = SelectFields.toDF()
DerivedColumn = DerivedColumn.withColumn(
    "snapshot_day",
    date_format(
        to_date(col("Order Date"), "MM-dd-yyyy"),
        "yyyy-MM-dd"
    )
)
DerivedColumn = DynamicFrame.fromDF(
    DerivedColumn, glueContext, "DerivedColumn"
)

# Write partitioned output
sink = glueContext.getSink(
    path="s3://ecommerce-order-details/orders-partitioned/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["snapshot_day"],
    enableUpdateCatalog=True
)
sink.setCatalogInfo(
    catalogDatabase="db_orders",
    catalogTableName="orders_partitioned"
)
sink.setFormat("glueparquet", compression="snappy")
sink.writeFrame(DerivedColumn)
