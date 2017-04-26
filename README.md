## Introduction

In this project, 

In this page, we first introduce a Web application which is used to collect participants' gaze data and reports of mind-wandering during watching lecture videos. Then we release the data about mind-wandering reports and the raw gaze data collected by both Tobii and WebGazer.js. After a brief introduction of the dataset, the experiment results and classifier parameters, which are not included in our papers due to the space limitation, are introduced concretely. In the last part, we introduce the scripts leveraged in our work for data processing and mind-wandering detection.
<!-- You can use the [editor on GitHub](https://github.com/Yue-ZHAO/MWDET_Project/edit/master/README.md) to maintain and preview the content for your website in Markdown files.

Whenever you commit to this repository, GitHub Pages will run [Jekyll](https://jekyllrb.com/) to rebuild the pages in your site, from the content in your Markdown files. -->

## Web Application for Experiments

In our experiments, participants interact with this Web application while Tobii studio runs in the background. When participants are watching lecture videos, their gaze data is recorded by both Tobii and the Web application at the same time. Their reports of mind-wandering are recorded by the Web application

During the experiments, participants are asked to watch two lecture videos (i.e. solar energy and nuclear energy). Before each video, there is a webcam setup and a calibration for WebGazer.js. In the webcam setup, participants are asked to make sure their faces are fully detected before the calibataion. In the calibration, participants are asked to click 40 dots randomly appearing in the screen.
The calibration of Tobii is conducted before the participants start interacting with the Web application. 

The detail setup information can be found in the repository of the Web application.

## Dataset

There are three folders for the following 3 kinds of data in the dataset. In each folder, a file contains the data of a participant.
1. Tobii Data (.csv files)
  - Coordinates (X, Y), timestamps, and durations of fixations
  - Angles of saccades
  - Coordinates (X, Y) and timestamps of gaze point

2. WebGazer Data (.csv files)
  - Coordinates (X, Y) and timestamp of gaze point 

3. Event Data (.json files)
  - Participants' report about their mind-wandering
  - The bell rings
  - Video playing status

The timestamps leveraged in this experiments are based on ISO 8601 (e.g. 2017-04-26T14:38:29.235Z) with UTC+0 timezone.

The video information (i.e. video playing time and video length) can be found from the event data. The lengths of the video about solar energy and the video about nuclear energy are about 468 seconds and 400 seconds respectively.

## Detection Results for Mind-Wandering



## Scripts 

<!-- Markdown is a lightweight and easy-to-use syntax for styling your writing. It includes conventions for

```markdown
Syntax highlighted code block

# Header 1
## Header 2
### Header 3

- Bulleted
- List

1. Numbered
2. List

**Bold** and _Italic_ and `Code` text

[Link](url) and ![Image](src)
```

For more details see [GitHub Flavored Markdown](https://guides.github.com/features/mastering-markdown/).

### Jekyll Themes

Your Pages site will use the layout and styles from the Jekyll theme you have selected in your [repository settings](https://github.com/Yue-ZHAO/MWDET_Project/settings). The name of this theme is saved in the Jekyll `_config.yml` configuration file.

### Support or Contact

Having trouble with Pages? Check out our [documentation](https://help.github.com/categories/github-pages-basics/) or [contact support](https://github.com/contact) and we’ll help you sort it out. -->
