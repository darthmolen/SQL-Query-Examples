DECLARE @PageNum int = 0
DECLARE	@PageSize int = 100
DECLARE	@FilterColumn NVARCHAR(255) = NULL
DECLARE @Filter NVARCHAR(MAX) = NULL
DECLARE @SortColumn NVARCHAR(255) = NULL
DECLARE @SortDirection NVARCHAR(255) = NULL

DECLARE @SubmitStartDate DateTime --= CAST('2018-05-02 13:04:00' AS DateTime) --Optional Filter
DECLARE @SubmitEndDate DateTime --= CAST('2018-05-02 13:04:50' AS DateTime) --Optional Filter
DECLARE @BeginStartDate DateTime = NULL --Optional Filter
DECLARE @BeginEndDate DateTime = NULL --Optional Filter
DECLARE @FinishStartDate DateTime = NULL --Optional Filter
DECLARE @FinishEndDate DateTime = NULL --Optional Filter




-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

-- Set up a bunch of default and make work before filtering and sorting
DECLARE @Start int, @End int, @OrderByClause varchar(100)
DECLARE @UseSubmitDate bit, @UseBeginDate bit, @UseFinishDate bit
DECLARE @MinDate DateTime, @MaxDate DateTime
DECLARE @FilterNum BIGINT

SELECT @MinDate = CAST('1/1/1753 12:00:00 AM' AS DateTime), @MaxDate = CAST('12/31/3999 11:59:00 PM' AS DateTime)

-- Add wildcard to filter if used
IF (@Filter IS NOT NULL AND (@FilterColumn = 'QueueName' OR @FilterColumn = 'TransactionName' OR @FilterColumn = 'HostName' OR @FilterColumn = 'JobUsed'))
	SELECT @Filter = '%' + @Filter + '%'
ELSE
	SELECT @FilterNum = CAST(@Filter AS BIGINT)

--Edge Case where the Pagenum might be null or less than 1
SELECT @PageNum = COALESCE(@PageNum,1)
SELECT @PageNum = CASE WHEN MIN(@PageNum) <= 0 THEN 1 ELSE @PageNum END

--Edge Case where the Pagesize might be null or less than 1
SELECT @PageSize = COALESCE(@PageSize,20)
SELECT @PageSize = CASE WHEN MIN(@PageSize) <= 0 THEN 20 ELSE @Pagesize END

SELECT @Start = CASE @PageNum WHEN 1 THEN 0 ELSE (@PageSize * (@PageNum - 1)) + 1 END
SELECT @End = @Start + @PageSize - CASE @PageNum WHEN 1 THEN 0 ELSE 1 END

SELECT @UseSubmitDate = CASE WHEN @SubmitStartDate IS NOT NULL THEN 1 ELSE 0 END, 
		@UseBeginDate = CASE WHEN @BeginStartDate IS NOT NULL THEN 1 ELSE 0 END,
		@UseFinishDate = CASE WHEN @FinishStartDate IS NOT NULL THEN 1 ELSE 0 END

SELECT @SubmitStartDate = COALESCE(@SubmitStartDate, @MinDate)
SELECT @SubmitStartDate = CASE WHEN @SubmitStartDate > @SubmitEndDate THEN @MinDate
							ELSE @SubmitStartDate END

SELECT @SubmitEndDate = COALESCE(@SubmitEndDate, @MaxDate)
SELECT @SubmitEndDate = CASE WHEN @SubmitEndDate < @SubmitStartDate THEN @MaxDate 
						WHEN  @SubmitEndDate = @SubmitStartDate  THEN dateadd(day,1,@SubmitEndDate) 
						ELSE @SubmitEndDate END

SELECT @BeginStartDate = COALESCE(@BeginStartDate, @MinDate)
SELECT @BeginStartDate = CASE WHEN @BeginStartDate > @SubmitEndDate THEN @MinDate
							ELSE @BeginStartDate END

SELECT @BeginEndDate = COALESCE(@BeginEndDate, @MaxDate)
SELECT @BeginEndDate = CASE WHEN @BeginEndDate < @BeginStartDate THEN @MaxDate 
						WHEN  @BeginEndDate = @BeginStartDate   THEN dateadd(day,1,@BeginEndDate) 
						ELSE @BeginEndDate END

SELECT @FinishStartDate = COALESCE(@FinishStartDate, @MinDate)
SELECT @FinishStartDate = CASE WHEN @FinishStartDate > @SubmitEndDate THEN @MinDate
							ELSE @FinishStartDate END

SELECT @FinishEndDate = COALESCE(@FinishEndDate, @MaxDate)
SELECT @FinishEndDate = CASE WHEN @FinishEndDate < @FinishStartDate THEN @MaxDate 
						WHEN  @FinishEndDate = @FinishStartDate THEN dateadd(day,1,@FinishEndDate) 
						ELSE @FinishEndDate END


SELECT [ID]
	  ,[QueueName]
      ,[TransactionName]
      ,[QueueID]
      ,[DeploymentID]
      ,[HostID]
	  ,[HostName]
      ,[Status]
      ,[NumberOfTimesAttempted]
      ,[JobUsed]
      ,[NumRecordsSubmitted]
      ,[NumRecordsProcessed]
      ,[NumPagesRendered]
      ,[WhenSubmitted]
      ,[WhenStarted]
      ,[WhenFinished]
	  ,[RowNum]
FROM
	(
	SELECT t.[ID]
		  ,q.[Name] AS 'QueueName'
		  ,[TransactionName]
		  ,[QueueID]
		  ,[DeploymentID]
		  ,[HostID]
		  ,h.[MachineName] AS 'HostName'
		  ,[Status]
		  ,[NumberOfTimesAttempted]
		  ,[JobUsed]
		  ,[NumRecordsSubmitted]
		  ,[NumRecordsProcessed]
		  ,[NumPagesRendered]
		  ,[WhenSubmitted]
		  ,[WhenStarted]
		  ,[WhenFinished]
		  ,Row_Number() OVER (ORDER BY
			CASE WHEN @SortColumn = 'QueueName' AND @SortDirection = 'asc' THEN CAST(q.[Name] as varchar(max)) END ASC,
			CASE WHEN @SortColumn = 'QueueName' AND @SortDirection = 'desc' THEN CAST(q.[Name] as varchar(max)) END DESC,
			CASE WHEN @SortColumn = 'TransactionName' AND @SortDirection = 'asc' THEN CAST([TransactionName] AS varchar(255)) END ASC,
			CASE WHEN @SortColumn = 'TransactionName' AND @SortDirection = 'desc' THEN CAST([TransactionName] AS varchar(255)) END DESC,
			CASE WHEN @SortColumn = 'QueueID' AND @SortDirection = 'asc' THEN [QueueID] END ASC,
			CASE WHEN @SortColumn = 'QueueID' AND @SortDirection = 'desc' THEN [QueueID] END DESC,
			CASE WHEN @SortColumn = 'DeploymentID' AND @SortDirection = 'asc' THEN [DeploymentID] END ASC,
			CASE WHEN @SortColumn = 'DeploymentID' AND @SortDirection = 'desc' THEN [DeploymentID] END DESC,
			CASE WHEN @SortColumn = 'HostID' AND @SortDirection = 'asc' THEN [HostID] END ASC,
			CASE WHEN @SortColumn = 'HostID' AND @SortDirection = 'desc' THEN [HostID] END DESC,
			CASE WHEN @SortColumn = 'HostName' AND @SortDirection = 'asc' THEN CAST(h.[MachineName] AS varchar(255)) END ASC,
			CASE WHEN @SortColumn = 'HostName' AND @SortDirection = 'desc' THEN CAST(h.[MachineName] AS varchar(255)) END DESC,
			CASE WHEN @SortColumn = 'Status' AND @SortDirection = 'asc' THEN [Status] END ASC,
			CASE WHEN @SortColumn = 'Status' AND @SortDirection = 'desc' THEN [Status] END DESC,
			CASE WHEN @SortColumn = 'NumberOfTimesAttempted' AND @SortDirection = 'asc' THEN [NumberOfTimesAttempted] END ASC,
			CASE WHEN @SortColumn = 'NumberOfTimesAttempted' AND @SortDirection = 'desc' THEN [NumberOfTimesAttempted] END DESC,
			CASE WHEN @SortColumn = 'JobUsed' AND @SortDirection = 'asc' THEN CAST([JobUsed] AS varchar(555)) END ASC,
			CASE WHEN @SortColumn = 'JobUsed' AND @SortDirection = 'desc' THEN CAST([JobUsed] AS varchar(555)) END DESC,
			CASE WHEN @SortColumn = 'NumRecordsSubmitted' AND @SortDirection = 'asc' THEN [NumRecordsSubmitted] END ASC,
			CASE WHEN @SortColumn = 'NumRecordsSubmitted' AND @SortDirection = 'desc' THEN [NumRecordsSubmitted] END DESC,
			CASE WHEN @SortColumn = 'NumRecordsProcessed' AND @SortDirection = 'asc' THEN [NumRecordsProcessed] END ASC,
			CASE WHEN @SortColumn = 'NumRecordsProcessed' AND @SortDirection = 'desc' THEN [NumRecordsProcessed] END DESC,
			CASE WHEN @SortColumn = 'NumPagesRendered' AND @SortDirection = 'asc' THEN [NumPagesRendered] END ASC,
			CASE WHEN @SortColumn = 'NumPagesRendered' AND @SortDirection = 'desc' THEN [NumPagesRendered] END DESC,
			CASE WHEN @SortColumn = 'WhenSubmitted' AND @SortDirection = 'asc' THEN [WhenSubmitted] END ASC,
			CASE WHEN @SortColumn = 'WhenSubmitted' AND @SortDirection = 'desc' THEN [WhenSubmitted] END DESC,
			CASE WHEN @SortColumn = 'WhenStarted' AND @SortDirection = 'asc' THEN [WhenStarted] END ASC,
			CASE WHEN @SortColumn = 'WhenStarted' AND @SortDirection = 'desc' THEN [WhenStarted] END DESC,
			CASE WHEN @SortColumn = 'WhenFinished' AND @SortDirection = 'asc' THEN [WhenFinished] END ASC,
			CASE WHEN @SortColumn = 'WhenFinished' AND @SortDirection = 'desc' THEN [WhenFinished] END DESC,
			CASE WHEN @SortColumn IS NULL THEN [WhenStarted] END DESC
		  ) as RowNum
	  FROM [Tasks] t
	  INNER JOIN [Queues] q ON t.QueueID = q.ID
	  INNER JOIN [Hosts] h ON t.HostId = h.ID
	  -- Apply Filters Here
	  WHERE 
	  -- Time Filters
		  (
			(@UseSubmitDate = 1 AND [WhenSubmitted] >= @SubmitStartDate AND [WhenSubmitted] <= @SubmitEndDate) OR
			(@UseBeginDate = 1 AND [WhenStarted] >= @BeginStartDate AND [WhenStarted] <= @BeginEndDate) OR
			(@UseFinishDate = 1 AND [WhenFinished] >= @FinishStartDate AND [WhenFinished] <= @FinishEndDate) OR
			(@UseSubmitDate = 0 AND @UseBeginDate = 0 AND @UseFinishDate = 0)
		  ) AND
	  -- Filter against a column
		 (
			@FilterColumn IS NULL OR
			(@FilterColumn = 'QueueName' AND q.[Name] LIKE @Filter) OR
			(@FilterColumn = 'TransactionName' AND t.TransactionName LIKE @Filter) OR
			(@FilterColumn = 'QueueId' AND t.QueueID = @FilterNum) OR -- doesn't need %%
			(@FilterColumn = 'HostId' AND t.HostId = @FilterNum) OR -- doesn't need %%
			(@FilterColumn = 'HostName' AND h.MachineName LIKE @Filter) OR
			(@FilterColumn = 'Status' AND t.[Status] = @FilterNum) OR -- doesn't need %%
			(@FilterColumn = 'NumberOfTimesAttempted' AND t.[NumberOfTimesAttempted] = @FilterNum) OR -- doesn't need %%
			(@FilterColumn = 'JobUsed' AND t.JobUsed LIKE @Filter) OR
			(@FilterColumn = 'NumRecordsSubmitted' AND t.NumRecordsSubmitted = @FilterNum) OR -- doesn't need %%
			(@FilterColumn = 'NumRecordsProcessed' AND t.NumRecordsProcessed = @FilterNum) OR  -- doesn't need %%
			(@FilterColumn = 'NumPagesRendered' AND t.NumPagesRendered = @FilterNum) -- doesn't need %%
		 )
	  ) AS r
	  WHERE r.RowNum BETWEEN @Start AND @End

SELECT Count(1) AS [RecordCount]
FROM [Tasks] t
	  INNER JOIN [Queues] q ON t.QueueID = q.ID
	  INNER JOIN [Hosts] h ON t.HostId = h.ID
	  -- Apply Filters Here
	  WHERE 
	  -- Time Filters
		  (
			(@UseSubmitDate = 1 AND [WhenSubmitted] >= @SubmitStartDate AND [WhenSubmitted] <= @SubmitEndDate) OR
			(@UseBeginDate = 1 AND [WhenStarted] >= @BeginStartDate AND [WhenStarted] <= @BeginEndDate) OR
			(@UseFinishDate = 1 AND [WhenFinished] >= @FinishStartDate AND [WhenFinished] <= @FinishEndDate) OR
			(@UseSubmitDate = 0 AND @UseBeginDate = 0 AND @UseFinishDate = 0)
		  ) AND
	  -- Filter against a column
		 (
			@FilterColumn IS NULL OR
			(@FilterColumn = 'QueueName' AND q.[Name] LIKE @Filter) OR
			(@FilterColumn = 'TransactionName' AND t.TransactionName LIKE @Filter) OR
			(@FilterColumn = 'QueueId' AND t.QueueID = @FilterNum) OR -- doesn't need %%
			(@FilterColumn = 'HostId' AND t.HostId = @FilterNum) OR -- doesn't need %%
			(@FilterColumn = 'HostName' AND h.MachineName LIKE @Filter) OR
			(@FilterColumn = 'Status' AND t.[Status] = @FilterNum) OR -- doesn't need %%
			(@FilterColumn = 'NumberOfTimesAttempted' AND t.[NumberOfTimesAttempted] = @FilterNum) OR -- doesn't need %%
			(@FilterColumn = 'JobUsed' AND t.JobUsed LIKE @Filter) OR
			(@FilterColumn = 'NumRecordsSubmitted' AND t.NumRecordsSubmitted = @FilterNum) OR -- doesn't need %%
			(@FilterColumn = 'NumRecordsProcessed' AND t.NumRecordsProcessed = @FilterNum) OR  -- doesn't need %%
			(@FilterColumn = 'NumPagesRendered' AND t.NumPagesRendered = @FilterNum) -- doesn't need %%
		 )

--SELECT @UseSubmitDate, @UseBeginDate, @UseFinishDate
--SELECT @SubmitStartDate, @SubmitEndDate