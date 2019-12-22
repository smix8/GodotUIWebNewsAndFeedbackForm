
# Godot UI InGame Web News and User Feedback Form
Example project made with Godot 3.2
News Example uses Google Drive for hosting text and image files
Feedback Example uses Google Forms for collecting user feedback

![ingame_web_request](https://user-images.githubusercontent.com/52464204/71317504-7ece0200-2482-11ea-853c-e046a3fb63b3.gif)

## Features | Examples:
- Template scene for showing ingame news and allowing users to send feedback with an ingame form
- Example for loading news data on button press from a web url that hosts a json file, e.g. your game server or webpage
- Example for loading new images from urls provided in the news json and saving them on the users system for reuse
- Example for a feedback form with category checkboxes and textinput that sends the data to a google form
- Example for update intervals and saving the acquired web data on the user system for reuse to prevent unintentional serverload
- Example for a user controlled button to give permission for the webrequests with settings saved in a persistent file
IMPORTANT: This is not enough from a law perspective, especially if you release a game for countries that are strict when it comes to user data like all countries from the European Union. Ask a friendly lawyer with a digital brain cell before you release your game to some countries with functionality from this example or something similar.
- Ruby colors!

## Setup | Usage

### Step 1 - Provide document URL(s)
In the `web.gd` script edit both the `news_json_file_url` and `web_form_url` with the paths to your online documents.

### Step 2 - Prepare News JSON file
Example for the minimum structure for the news json file
```json
{
	"news_id" : 0,    
	"image" : "https://drive.google.com/uc?export=view&id=MY_IMAGE_URL_WITH_ULTRA_LONG_RANDOMSYMBOLS_AND_NUMBERS",  
	"text" : "just news dummy text"
}
```
Add as many other `key:value` pairs to the `json` as you need and read them with `news.get("key_name")` inside the `web.gd` script or with `game.web.news.get("key_name")` from everywhere in your project.

The `news_id` is saved on the users system. Everytime the saved users `news_id` is lower than the `news_id` from the server the user gets an update notification. If you want to throw another news notification to your userbase just update the json on your server and increase the `news_id` number by `+1`.

The `image` is for the weburl loadingpath to your image file. If you need more than one image in your news customize the `_on_NEWS_HTTPRequest_completed()` function.

The `text` yeah is just that, plain text for the display.

If you host it on google drive you get the `json url` by creating a `shareable link` for your json file.

### Step 3 - Provide form document keys
Depending on the layout of your feedback form you must edit certain variables. You get the `form url` by creating a `shareable link` for your form document and the `key names` by creating a `prefilled form` and a `copylink` that will contain the excact keynames.

In the `send_form_data()` function you need to edit the entry numbers in the `form_data_to_send` variable with your keys from the online form.

In case you use `checkboxes` or something similar on the form you need to prepare those string keys for the user. Make sure that you send the excact string value representing the users choice to the form.

If you don't prepare this everything will be send and show no error but the form will not know where to add it to the database and dismiss it.


## License
Roboto font has its own Apache license. MIT or my personal 'Don't care' license everything else. Do whatever you want with this example and keep your users updated with news while collecting their feedback in Godot.

## Known Issues
...