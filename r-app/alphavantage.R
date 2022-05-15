library(ggplot2)
library(jsonlite)
library(plumber)
library(stringr)

apiKey <- 'YOUR API KEY'

getSymbols <- function() {
  path <- 'data/symbols.Rda'
  if (!file.exists(path)) {
    symbols <- c()
    save(symbols, file = path)
  } else {
    load(file = path)    
  }
  toJSON(symbols)
}

setSymbol <- function(symbol = '') {
  path <- 'data/symbols.Rda'
  if (!file.exists(path)) {
    symbols <- c()
  } else {
    load(file = path)    
  }  
  if (!(symbol %in% symbols)) {
    symbols <- append(symbols, c(symbol))    
  }
  symbols <- sort(symbols)
  save(symbols, file = path)
}

#* assets
#* 
#* @assets ./assets /assets
#* 
list()

#* index
#* 
#* @serializer html
#* @get /
#* @post /
#* 
index <- function(req, res, symbol = '') {
  symbol = str_trim(symbol, side = c('both'))
  overview <- data.frame(Symbol = '', Name = '', Description = '', Exchange = '', Currency = '', Country = '',  Sector = '')
  if (str_length(symbol) > 0) {
    url <- str_replace_all('https://www.alphavantage.co/query?function=OVERVIEW&symbol=@Symbol@&apikey=@ApiKey@', c('@Symbol@' = symbol, '@ApiKey@' = apiKey))
    temp <- jsonlite::fromJSON(txt = url) 
    if (length(temp) > 0) {
      overview <- temp
      if (!is.null(overview$Symbol)) {
        setSymbol(symbol = overview$Symbol)
      }
    }
  }
  page <- paste(readLines('views/index.html'), collapse = '\n')
  page <- str_replace_all(page, c(
    '@Symbol@'= ifelse(is.null(overview$Symbol), '', overview$Symbol),
    '@Name@'= ifelse(is.null(overview$Name), '', overview$Name),
    '@Description@' = ifelse(is.null(overview$Description), '', overview$Description),
    '@Exchange@' = ifelse(is.null(overview$Exchange), '', overview$Exchange),
    '@Currency@'= ifelse(is.null(overview$Currency), '', overview$Currency),
    '@Country@'= ifelse(is.null(overview$Country), '', overview$Country),
    '@Sector@'= ifelse(is.null(overview$Sector), '', overview$Sector)
  ))
  page <- str_replace_all(page, '@Symbols@', getSymbols())
  page
}

#* dayInfoChart
#* 
#* @serializer contentType list(type='image/png')
#* @get /dayinfochart
#* 
dayInfoChart <- function(req, res, symbol = '') {
  f <- 'assets/images/nothing.png'
  symbol = str_trim(symbol, side = c('both'))
  if (str_length(symbol) > 0) {
    url <- str_replace_all('https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol=@Symbol@&interval=60min&outputsize=compact&apikey=@ApiKey@', c('@Symbol@' = symbol, '@ApiKey@' = apiKey))
    intraday <- jsonlite::fromJSON(txt = url)
    if (length(intraday) > 0) {
      symbol = intraday$'Meta Data'$'2. Symbol'
      if (!is.null(symbol)) {
        firstDate <- str_sub(names(intraday$'Time Series (60min)'[1]), 1, 10)
        intraday <- intraday$'Time Series (60min)'
        intraday <- intraday[str_detect(names(intraday), firstDate) == TRUE]
        index <- 1
        temp <- data.frame(Open = c(1), High = c(2), Low = c(3), Close = c(4), Volume = c(5), Hour = c(6))
        for (element in intraday) {
          element <- append(element, list(Hour = str_sub(c(names(intraday[index])), 12)))
          temp[nrow(temp) + 1,] <- element
          index = index + 1
        }        
        intraday <- temp[-1,]
        intraday$Open <- as.numeric(intraday$Open)
        intraday$Open <- round(intraday$Open, digits = 2)
        intraday$High <- as.numeric(intraday$High)
        intraday$High <- round(intraday$High, digits = 2)
        intraday$Low <- as.numeric(intraday$Low)
        intraday$Low <- round(intraday$Low, digits = 2)
        intraday$Close <- as.numeric(intraday$Close)
        intraday$Close <- round(intraday$Close, digits = 2)
        intraday$Volume <- as.numeric(intraday$Volume)
        chart <- ggplot(data = intraday, aes(x = Hour, y = Close)) +
          geom_line(colour = '#ffad99', size = 2, linetype = 1, group = 1) +
          geom_point(colour = '#808080', size = 4) +
          labs(title = paste(symbol, firstDate, sep = ' / '), x = '', y = '') +
          geom_text(aes(label = format(x = Close)), vjust = 1.6, color = '#000000', size = 4) +
          theme(plot.title = element_text(hjust = 0.5, face = 'bold'),
                axis.text.x = element_text(angle = 60, hjust = 1, face = 'bold', size = 10),
                axis.text.y = element_text(face = 'bold', size = 10)
          )               
        f <- 'temporary/dayinfochart.png'
        suppressMessages(ggsave(f, chart))
      }
    }
  }
  readBin(f, 'raw', n = file.info(f)$size)
}

#* monthlyInfoChart
#* 
#* @serializer contentType list(type='image/png')
#* @get /monthlyinfochart
#* 
monthlyInfoChart <- function(req, res, symbol = '') {
  f <- 'assets/images/nothing.png'
  symbol = str_trim(symbol, side = c('both'))
  if (str_length(symbol) > 0) {
    url <- str_replace_all('https://www.alphavantage.co/query?function=TIME_SERIES_MONTHLY&symbol=@Symbol@&apikey=@ApiKey@', c('@Symbol@' = symbol, '@ApiKey@' = apiKey))
    monthly <- jsonlite::fromJSON(txt = url)
    if (length(monthly) > 0) {
      symbol = monthly$'Meta Data'$'2. Symbol'
      if (!is.null(symbol)) {
        firstYear <- str_sub(names(monthly$'Monthly Time Series'[1]), 1, 4)
        monthly <- monthly$'Monthly Time Series'
        monthly <- monthly[str_detect(names(monthly), firstYear) == TRUE]
        index <- 1
        temp <- data.frame(Open = c(1), High = c(2), Low = c(3), Close = c(4), Volume = c(5), Month = c(6))
        for (element in monthly) {
          element <- append(element, list(Month = paste(str_sub(c(names(monthly[index])), 6, 7), month.abb[as.numeric(str_sub(c(names(monthly[index])), 6, 7))], sep = ' - ')))
          temp[nrow(temp) + 1,] <- element
          index = index + 1
        }
        monthly <- temp[-1,]
        monthly$Open <- as.numeric(monthly$Open)
        monthly$Open <- round(monthly$Open, digits = 2)
        monthly$High <- as.numeric(monthly$High)
        monthly$High <- round(monthly$High, digits = 2)
        monthly$Low <- as.numeric(monthly$Low)
        monthly$Low <- round(monthly$Low, digits = 2)
        monthly$Close <- as.numeric(monthly$Close)
        monthly$Close <- round(monthly$Close, digits = 2)
        monthly$Volume <- as.numeric(monthly$Volume) 
        chart <- ggplot(data = monthly, aes(x = Month, y = Close)) +
          geom_line(colour = '#ffad99', size = 2, linetype = 1, group = 1) +
          geom_point(colour = '#808080', size = 4) +
          labs(title = paste(symbol, firstYear, sep = ' / '), x = '', y = '') +
          geom_text(aes(label = format(x = Close)), vjust = 1.6, color = '#000000', size = 4) +
          theme(plot.title = element_text(hjust = 0.5, face = 'bold'),
                axis.text.x = element_text(angle = 60, hjust = 1, face = 'bold', size = 10),
                axis.text.y = element_text(face = 'bold', size = 10)
          )               
        f <- 'temporary/monthlyinfochart.png'
        suppressMessages(ggsave(f, chart))
      }
    }
  }
  readBin(f, 'raw', n = file.info(f)$size)  
}

#* weeklyInfoChart
#* 
#* @serializer contentType list(type='image/png')
#* @get /weeklyinfochart
#* 
weeklyInfoChart <- function(req, res, symbol = '') {
  f <- 'assets/images/nothing.png'
  symbol = str_trim(symbol, side = c('both'))
  if (str_length(symbol) > 0) {
    url <- str_replace_all('https://www.alphavantage.co/query?function=TIME_SERIES_WEEKLY&symbol=@Symbol@&apikey=@ApiKey@', c('@Symbol@' = symbol, '@ApiKey@' = apiKey))
    weekly <- jsonlite::fromJSON(txt = url)
    if (length(weekly) > 0) {
      symbol = weekly$'Meta Data'$'2. Symbol'
      if (!is.null(symbol)) {
        ordinal <- c('1st Week', '2nd Week', '3rd Week', '4th Week', '5th Week')
        firstYearAndMonth <- str_sub(names(weekly$'Weekly Time Series'[1]), 1, 7)
        weekly <- weekly$'Weekly Time Series'
        weekly <- weekly[str_detect(names(weekly), firstYearAndMonth) == TRUE]
        index <- 1
        temp <- data.frame(Open = c(1), High = c(2), Low = c(3), Close = c(4), Volume = c(5), Week = c(6))
        for (element in rev(weekly)) {          
          element <- append(element, list(Week = ordinal[index]))
          temp[nrow(temp) + 1,] <- element
          index = index + 1
        }
        weekly <- temp[-1,]
        weekly$Open <- as.numeric(weekly$Open)
        weekly$Open <- round(weekly$Open, digits = 2)
        weekly$High <- as.numeric(weekly$High)
        weekly$High <- round(weekly$High, digits = 2)
        weekly$Low <- as.numeric(weekly$Low)
        weekly$Low <- round(weekly$Low, digits = 2)
        weekly$Close <- as.numeric(weekly$Close)
        weekly$Close <- round(weekly$Close, digits = 2)
        weekly$Volume <- as.numeric(weekly$Volume)
        chart <- ggplot(data = weekly, aes(x = Week, y = Close)) +
          geom_line(colour = '#ffad99', size = 2, linetype = 1, group = 1) +
          geom_point(colour = '#808080', size = 4) +
          labs(title = paste(symbol, str_sub(firstYearAndMonth, 1, 4), month.abb[as.numeric(str_sub(firstYearAndMonth, 6, 7))], sep = ' / '), x = '', y = '') +
          geom_text(aes(label = format(x = Close)), vjust = 1.6, color = '#000000', size = 4) +
          theme(plot.title = element_text(hjust = 0.5, face = 'bold'),
                axis.text.x = element_text(angle = 60, hjust = 1, face = 'bold', size = 10),
                axis.text.y = element_text(face = 'bold', size = 10)
          )               
        f <- 'temporary/weeklyinfochart.png'
        suppressMessages(ggsave(f, chart))
      }
    }
  }
  readBin(f, 'raw', n = file.info(f)$size)  
}
