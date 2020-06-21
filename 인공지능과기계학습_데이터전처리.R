# install.packages("RMySQL")
# install.packages("lubridate")
# install.packages("dplyr")

library(RMySQL) 
library(lubridate)
library(dplyr)

## xx대학교 전력 데이터는 충북대 데이터베이스에 copy되어 있으므로 충북대의 "ITRC_Copy" db와 연결한다.
con <- dbConnect(MySQL(), user="itrc", password="itrc", host="x.xxx.xxx.xxx", port=xxxx, dbname = "ITRC_Copy")

# 내 컴퓨터(내가 사용하는 서버)에 ITRC_1F_GROUP 테이블을 가져와보자.
ITRC_1F_GROUP <- dbGetQuery(con, "SELECT * FROM ITRC_1F_GROUP;")
head(ITRC_1F_GROUP)

# DB연결 종료
dbDisconnect(con)

#데이터 용량 감소를 위해 시간과 Active_Power만 추출
ITRC_1F_GROUP <- subset(ITRC_1F_GROUP,select = c(`Date:Time`,Active_Power))

#1분당 하나의 데이터가 있으므로 분 단위로 추출
ITRC_1F_GROUP$`Date:Time` <- substr(ITRC_1F_GROUP$`Date:Time`,1,16)
names(ITRC_1F_GROUP) <- c("DateTime","ActivePower")


# 원하는 날짜만큼 데이터 추출
start_t = which(ITRC_1F_GROUP$DateTime == '2019-06-01 00:00')
end_t = which(ITRC_1F_GROUP$DateTime == '2019-12-24 00:00')
ITRC_1F_GROUP <- ITRC_1F_GROUP[c(start_t:end_t),]


# 이상치(AP 1000 이하 - 임의로 정함) NA 값으로 대체
ITRC_1F_GROUP[ITRC_1F_GROUP$ActivePower < 1000, "ActivePower"] = NA
sum(is.na(ITRC_1F_GROUP))


# 전력데이터에서 빠진 시간 적용
Date_time <- read.csv("C:/Users/ty009/문서/ITRC/Date.csv", header = T)
Date_time$Date_T <- as.character(Date_time$Date_T)
str(Date_time)
ITRC_1F_GROUP_AP <- left_join(Date_time, ITRC_1F_GROUP, by=c("Date_T" = "DateTime"))
names(ITRC_1F_GROUP_AP) <- c("DateTime","ActivePower")



# 모든 데이터에서 13~14시가 빠져 있으므로 13시의 데이터 제거
ITRC_1F_GROUP_AP$hour <- substr(ITRC_1F_GROUP_AP$DateTime,12,13)
ITRC_1F_GROUP_AP <- ITRC_1F_GROUP_AP[!(ITRC_1F_GROUP_AP$hour == "13" ), ]
ITRC_1F_GROUP_AP <- subset(ITRC_1F_GROUP_AP,select = c(DateTime,ActivePower))
sum(is.na(ITRC_1F_GROUP_AP))



# 날씨 데이터
SURFACE_ASOS <- read.csv("C:/Users/ty009/문서/기상청/SURFACE_ASOS_2019_2half.csv", header = T)
SURFACE_ASOS$일시 <- as.character(SURFACE_ASOS$일시)

# Join
ITRC_1F_GROUP_AP <- left_join(ITRC_1F_GROUP_AP, SURFACE_ASOS, by=c(DateTime = "일시"))
#ITRC_1F_GROUP_AP <- subset(ITRC_1F_GROUP_AP,select = c(1,2,4,10))
names(ITRC_1F_GROUP_AP) <- c("DateTime","ActivePower","Temperature","Humidity")




# Date:Time는 날짜와 시간 형식으로 변경한다.
ITRC_1F_GROUP_AP$DateTime <- as.POSIXct(ITRC_1F_GROUP_AP$DateTime, format = "%Y-%m-%d %H:%M")
ITRC_1F_GROUP_AP$WeekDay <- weekdays(ITRC_1F_GROUP_AP$DateTime)

# 요일 형식을 변경한다.
ITRC_1F_GROUP_AP$WeekDay <- gsub('월요일', '1', ITRC_1F_GROUP_AP$WeekDay)
ITRC_1F_GROUP_AP$WeekDay <- gsub('화요일', '2', ITRC_1F_GROUP_AP$WeekDay)
ITRC_1F_GROUP_AP$WeekDay <- gsub('수요일', '3', ITRC_1F_GROUP_AP$WeekDay)
ITRC_1F_GROUP_AP$WeekDay <- gsub('목요일', '4', ITRC_1F_GROUP_AP$WeekDay)
ITRC_1F_GROUP_AP$WeekDay <- gsub('금요일', '5', ITRC_1F_GROUP_AP$WeekDay)
ITRC_1F_GROUP_AP$WeekDay <- gsub('토요일', '6', ITRC_1F_GROUP_AP$WeekDay)
ITRC_1F_GROUP_AP$WeekDay <- gsub('일요일', '0', ITRC_1F_GROUP_AP$WeekDay)


# 열 순서 변경
ITRC_1F_GROUP_AP <- ITRC_1F_GROUP_AP[,c(1,5,3,4,2)]

write.csv(ITRC_1F_GROUP_AP, file = "C:/Users/ty009/문서/ITRC/ITRC_1F_GROUP_2ndHalf.csv", row.names = F)

