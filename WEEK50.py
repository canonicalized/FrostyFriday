# The Snowpark package is required for Python Worksheets. 
# You can add more packages by selecting them using the Packages control and then importing them.

import snowflake.snowpark as snowpark
from snowflake.snowpark.functions import col

def python_way(session: snowpark.Session): 
    # Your code goes here, inside the "main" handler.
    tableName = 'CHALLENGES.F_F_50'
    dataframe = session.table(tableName).filter(col("last_name") == 'Deery')

    # Print a sample of the dataframe to standard output.
    dataframe.show()

    # Return value will appear in the Results tab.
    return dataframe

def sql_way(session: snowpark.Session):
    tableName = 'CHALLENGES.F_F_50'
    dataframe = session.sql(f"SELECT * FROM {tableName} WHERE LAST_NAME = 'Deery'")
    return dataframe

def main(session: snowpark.Session):
    return python_way(session)
