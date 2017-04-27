# The input file should be preprocessed, the data format is
# GazeX_b_px,GazeY_b_px,Timestamp_utc,Video_length,Video_time,GazeX_s_px,GazeY_s_px
# What we main focus are Timestamp_utc, GazeX_s_px, GazeY_s_px
# We use Video_length to split the data into two trials
rad2deg <- function(rad) {(rad * 180) / (pi)}
deg2rad <- function(deg) {(deg * pi) / (180)}

# Implementation of the Engbert & Kliegl algorithm for the
# detection of saccades.  This function takes a data frame of the
# samples and adds three columns:
#
# - A column named "saccade" which contains booleans indicating
#   whether the sample occurred during a saccade or not.
# - Columns named vx and vy which indicate the horizontal and vertical
#   speed.
saccades_detection <- function(samples, lambda, smooth.saccades) {

  library("zoom")
  # Calculate horizontal and vertical velocities:
  vx <- stats::filter(samples$x, -1:1/2)
  vy <- stats::filter(samples$y, -1:1/2)

  # We don't want NAs, as they make our life difficult later
  # on.  Therefore, fill in missing values:
  vx[1] <- vx[2]
  vy[1] <- vy[2]
  vx[length(vx)] <- vx[length(vx)-1]
  vy[length(vy)] <- vy[length(vy)-1]

  msdx <- sqrt(median(vx**2, na.rm=T) - median(vx, na.rm=T)**2)
  msdy <- sqrt(median(vy**2, na.rm=T) - median(vy, na.rm=T)**2)

  radiusx <- msdx * lambda
  radiusy <- msdy * lambda

  sacc <- ((vx/radiusx)**2 + (vy/radiusy)**2) > 1
  if (smooth.saccades) {
    sacc <- stats::filter(sacc, rep(1/3, 3))
    sacc <- as.logical(round(sacc))
  }
  samples$saccade <- ifelse(is.na(sacc), F, sacc)
  samples$vx <- vx
  samples$vy <- vy

  samples

}

fixation_webgazerdata_preprocess <- function(input_filename){
	
	df_webgazerdata <- read.csv2(input_filename, sep=",")

    # Data Preprocessing
	df_webgazerdata <- df_webgazerdata[!duplicated(df_webgazerdata), ]
	df_webgazerdata$Timestamp_utc <- strptime(df_webgazerdata$Timestamp_utc, "%Y-%m-%dT%H:%M:%OSZ")
	op <- options(digits.secs=3)
	df_webgazerdata$GazeX_b_px <- as.numeric(as.character(df_webgazerdata$GazeX_b_px))
	df_webgazerdata$GazeY_b_px <- as.numeric(as.character(df_webgazerdata$GazeY_b_px))
	df_webgazerdata$Video_length <- as.numeric(as.character(df_webgazerdata$Video_length))
	df_webgazerdata$Video_time <- as.numeric(as.character(df_webgazerdata$Video_time))
	df_webgazerdata$GazeX_s_px <- as.numeric(as.character(df_webgazerdata$GazeX_s_px))
	df_webgazerdata$GazeY_s_px <- as.numeric(as.character(df_webgazerdata$GazeY_s_px))

	# Calculate trials
	temp_list_videolength <- unique(df_webgazerdata$Video_length)	
	df_webgazerdata$trial <- 1
	for(i in 1:length(temp_list_videolength)) {
		df_webgazerdata[which(df_webgazerdata$Video_length == temp_list_videolength[i]), "trial"] <- i
	}

	# Calculate time
	df_webgazerdata$time <- as.numeric(difftime(df_webgazerdata$Timestamp_utc, min(df_webgazerdata$Timestamp_utc))) * 1000

	# Calculate x and y
	df_webgazerdata$x <- df_webgazerdata$GazeX_s_px
	df_webgazerdata$y <- df_webgazerdata$GazeY_s_px

	return(df_webgazerdata)
}

fixation_webgazerdata_execute <- function(df_webgazerdata, lambda){

	library("zoom")
	library("saccades")

	# Engbert, Ralf, and Reinhold Kliegl. 
	# "Microsaccades uncover the orientation of covert attention." 
	# Vision research 43.9 (2003): 1035-1045.
	df_webgazerdata <- saccades_detection(df_webgazerdata,  lambda = 1, smooth.saccades=T)

	return(df_webgazerdata)
}

# In our method, we use method to detect saccades. 
# Since the detection requency is about 5Hz, which means that the timespan between two timestamp is about 200ms. 
# However, based on previous work(??), the fixation is about 100 ms to 800 ms, which means that we can not detect fixation accurately
# 
fixation_webgazerdata_postprocess <- function(df_webgazerdata){    
    # Curently, we measure whether the movement bewteen previous eye gaze point and current eye gaze point is a saccade.
    # Then we calculate FixationIndex, FixationPointX (MCSpx), FixationPointY (MCSpx), GazeEventDuration, AbsoluteSaccadicDirection

    df_webgazerdata[, "FixationIndex"] <- NA
    df_webgazerdata[, "FixationPointX (MCSpx)"] <- NA
    df_webgazerdata[, "FixationPointY (MCSpx)"] <- NA
    df_webgazerdata[, "GazeEventDuration"] <- NA
    df_webgazerdata[, "AbsoluteSaccadicDirection"] <- NA

    temp_index_fixation <- 1
    temp_trial <- 1
    for (i in 1:nrow(df_webgazerdata)) {

    	if (df_webgazerdata[i, "saccade"] == FALSE) {
    		# FixationIndex
    		# Flase means it is the same fixation from the previous point to the current point
    		if (df_webgazerdata[i, 'trial'] == temp_trial) {
    			df_webgazerdata[i, 'FixationIndex'] <- temp_index_fixation
    		} else {
    			temp_index_fixation <- temp_index_fixation + 1
    			df_webgazerdata[i, 'FixationIndex'] <- temp_index_fixation
    			temp_trial <- df_webgazerdata[i, 'trial']
    		}

    	} else {
    		# FixationIndex
    		# True means we move to a new fixation
    		temp_index_fixation <- temp_index_fixation + 1
    		df_webgazerdata[i, 'FixationIndex'] <- temp_index_fixation
    		if (df_webgazerdata[i, 'trial'] != temp_trial) {
    			temp_trial <- df_webgazerdata[i, 'trial']
    		}
    	}
	}

	list_fixationindex <- unique(df_webgazerdata$FixationIndex)
	for (temp_index in list_fixationindex) {

		df_webgazerdata[which(df_webgazerdata$FixationIndex==temp_index), "FixationPointX (MCSpx)"] <- mean(df_webgazerdata[which(df_webgazerdata$FixationIndex==temp_index),'x'])
		df_webgazerdata[which(df_webgazerdata$FixationIndex==temp_index), "FixationPointY (MCSpx)"] <- mean(df_webgazerdata[which(df_webgazerdata$FixationIndex==temp_index),'y'])
		df_webgazerdata[which(df_webgazerdata$FixationIndex==temp_index), "GazeEventDuration"] <- max(df_webgazerdata[which(df_webgazerdata$FixationIndex==temp_index),'time']) - min(df_webgazerdata[which(df_webgazerdata$FixationIndex==temp_index),'time']) 
	}

	# GazeEventDuration generation
	temp_trial <- 1
	for (i in 1:nrow(df_webgazerdata)) {
		if (i == 1) {
			df_webgazerdata[i, 'GazeEventDuration'] <- 0
			temp_trial <- df_webgazerdata[i, 'trial']
		} else {
			if (df_webgazerdata[i, 'trial'] == temp_trial) {
				if (df_webgazerdata[i, 'GazeEventDuration'] == 0){
					df_webgazerdata[i, 'GazeEventDuration'] <- df_webgazerdata[i, 'time'] - df_webgazerdata[i-1, 'time']
				}
			} else {
				df_webgazerdata[i, 'GazeEventDuration'] <- 0
				temp_trial <- df_webgazerdata[i, 'trial']
			}
		}
	}

	# AbsoluteSaccadicDirection
	temp_fixation_index_2 <- 0
	temp_AbsoluteSaccadicDirection <- 0
	temp_FixationPointX <- 0
	temp_FixationPointY <- 0
	for (i in 1:nrow(df_webgazerdata)) {
		if (i == 1) {
			# Initialize temp_fixation_index_2, temp_AbsoluteSaccadicDirection, temp_FixationPointX, temp_FixationPointY
			temp_fixation_index_2 <- df_webgazerdata[i, 'FixationIndex']
			df_webgazerdata[i, 'AbsoluteSaccadicDirection'] <- 0
			temp_AbsoluteSaccadicDirection <- 0
			temp_FixationPointX <- df_webgazerdata[i, 'FixationPointX (MCSpx)']
			temp_FixationPointY <- df_webgazerdata[i, 'FixationPointY (MCSpx)']
		} else {
			if (df_webgazerdata[i, 'FixationIndex'] == temp_fixation_index_2) {
				df_webgazerdata[i, 'AbsoluteSaccadicDirection'] <- df_webgazerdata[i-1, 'AbsoluteSaccadicDirection']
			} else {
				# different trial
				# Initialize temp_fixation_index_2, temp_AbsoluteSaccadicDirection, temp_FixationPointX, temp_FixationPointY
				if (df_webgazerdata[i, 'trial'] != df_webgazerdata[i, 'trial']) {
					temp_fixation_index_2 <- df_webgazerdata[i, 'FixationIndex']
					df_webgazerdata[i, 'AbsoluteSaccadicDirection'] <- 0
					temp_AbsoluteSaccadicDirection <- 0
					temp_FixationPointX <- df_webgazerdata[i, 'FixationPointX (MCSpx)']
					temp_FixationPointY <- df_webgazerdata[i, 'FixationPointY (MCSpx)']
				} else {
				# same trial, different fixation
				# set 
					temp_fixation_index_2 <- df_webgazerdata[i, 'FixationIndex']
					temp_AbsoluteSaccadicDirection <- rad2deg(atan((df_webgazerdata[i, 'FixationPointY (MCSpx)']-temp_FixationPointY)/(df_webgazerdata[i, 'FixationPointX (MCSpx)']-temp_FixationPointX)))
					temp_FixationPointX <- df_webgazerdata[i, 'FixationPointX (MCSpx)']
					temp_FixationPointY <- df_webgazerdata[i, 'FixationPointY (MCSpx)']
					df_webgazerdata[i, 'AbsoluteSaccadicDirection'] <- temp_AbsoluteSaccadicDirection
				}
			}
		}
	}

	require(zoo)
	df_webgazerdata <- transform(df_webgazerdata, AbsoluteSaccadicDirection = na.locf(AbsoluteSaccadicDirection))

	drops <- c("x","y","time")
	df_webgazerdata <- df_webgazerdata[ , !(names(df_webgazerdata) %in% drops)]
    return(df_webgazerdata)

}

fixation_webgazerdata_trans <- function(input_folderpath, output_folderpath){
	list_filename <- list.files(input_folderpath, pattern="*.csv")
	for (filename in list_filename) {

		# Get filename
		filepath_preprocessed <- paste(input_folderpath, filename, sep="/")

		# Generate fixations and saccades
		df_webgazerdata <- fixation_webgazerdata_preprocess(filepath_preprocessed)
		df_webgazerdata <- fixation_webgazerdata_execute(df_webgazerdata, lambda=1)
		df_webgazerdata <- fixation_webgazerdata_postprocess(df_webgazerdata)
		
		# Write dataframe into a file in output folder
		filepath_output <- paste(output_folderpath, filename, sep="/")
		write.csv(x = df_webgazerdata, file = filepath_output, sep = ",", dec=".")
	}
}
