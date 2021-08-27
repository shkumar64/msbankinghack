CREATE VIEW [dbo].[finalreport]
	AS SELECT * FROM
	 OPENROWSET( 
       'CosmosDB',
       'Account=<>yourcosmosaccoutname>;Database=fsi-marketdata;Key=<Youraccountkey>',
       fintransactions) with (TransactionAmount BIGINT, isFraud INT, OFACviolation INT, State VARCHAR(200), TransactionType VARCHAR(200) ) as rows 

