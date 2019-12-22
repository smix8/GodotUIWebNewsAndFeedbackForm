extends Node


##########################################
### Helper node to get news data from, or post feedback data to a webserver
###	for news e.g. a shared .json file on a google drive already works
### for feedback e.g. a shared google forms doc can accept the posts made by players

signal web_news_update_received
signal web_forms_update_received

### BEGIN SETUP

const news_json_file_url = "https://drive.google.com/uc?export=view&id=MY_JSON_URL_WITH_ULTRA_LONG_RANDOMSYMBOLS_AND_NUMBERS"
### this is an example for a json news file hosted on a google drive
### you get the url by creating a shareable link for your json file on your google drive

####################################################################################
###
### EXAMPLE FOR THE NEWS JSON FILE
###
###		{
###	    	"news_id" : 0,    
###	    	"image" : "https://drive.google.com/uc?export=view&id=MY_IMAGE_URL_WITH_ULTRA_LONG_RANDOMSYMBOLS_AND_NUMBERS",  
###	    	"text" : "just news dummy text"
###		}
###
### "news_id" everytime the saved users news_id is lower than the news_id from the server the user gets an update notification
### if you want to throw another news update just update the json on your server and increase the 'news_id' number by +1
###
### "image" the weburl loadingpath for your image file
### If you need more than one image in your news customize the '_on_NEWS_HTTPRequest_completed' function
###
### "text" yeah just text to display
###
### Add as many other key:value pairs to the json as you need and read them with 'news.get("key_name")'
###
####################################################################################


const web_form_url = "https://docs.google.com/forms/d/e/MY_FORM_URL_WITH_ULTRA_LONG_RANDOMSYMBOLS_AND_NUMBERS/formResponse"
### this is an example for a google forms doc
### you get the url/keys by creating prefill forms and than look at the copy link url in your browser
### add the keys for your form buttons and text fields in the send_form_data() function by editing the 'form_data_to_send' variable



### resets disabled buttons after some time in case something goes wrong with the web requests
export(float) var timeout_threshold = 5.0
var timeout : float = 0.0

### use 'if game.web.unread_news == true:' to toggle custom displays for your users when fresh news are available
var unread_news : bool = false
### only make webrequests when the user gave permission, default should always be false for law reasons
var permit_web_requests : bool = false

### needs to be saved in a persistent file and reloaded on game start to have an effect
var current_news_id : int = 0
var last_news_request_time : int = 0
var last_send_feedback_time : int = 0

### the amount of days to wait until we check for news again to not flood the server with requests
const NEWS_CHECK_INTERVAL_DAYS : int = 1

### END SETUP


onready var http_news : HTTPRequest = $News_HTTPRequest
onready var http_forms : HTTPRequest = $Forms_HTTPRequest
onready var http_images : HTTPRequest = $Images_HTTPRequest
onready var web_menu = $Web_CanvasLayer/Web_Menu

onready var permit_web_requests_button = $Web_CanvasLayer/Web_Menu/MarginContainer/PanelContainer/VBoxContainer/CenterContainer/Check_Web_Requests
onready var feedback_text_node = $Web_CanvasLayer/Web_Menu/MarginContainer/PanelContainer/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer2/MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Feedback_TextEdit
onready var news_image = $Web_CanvasLayer/Web_Menu/MarginContainer/PanelContainer/VBoxContainer/HBoxContainer/PanelContainer/VBoxContainer/MarginContainer2/PanelContainer/MarginContainer/VBoxContainer/News_Image
onready var news_text_node = $Web_CanvasLayer/Web_Menu/MarginContainer/PanelContainer/VBoxContainer/HBoxContainer/PanelContainer/VBoxContainer/MarginContainer2/PanelContainer/MarginContainer/VBoxContainer/News_Text
onready var version_label = $Web_CanvasLayer/Web_Menu/MarginContainer/PanelContainer/VBoxContainer/Version

onready var choice1_button = $Web_CanvasLayer/Web_Menu/MarginContainer/PanelContainer/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer2/MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CheckBox_Feedback
onready var choice2_button = $Web_CanvasLayer/Web_Menu/MarginContainer/PanelContainer/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer2/MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CheckBox_Bugreport
onready var choice3_button = $Web_CanvasLayer/Web_Menu/MarginContainer/PanelContainer/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer2/MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CheckBox_Question
onready var send_form_button = $Web_CanvasLayer/Web_Menu/MarginContainer/PanelContainer/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer2/Send_Form_Button
onready var get_news_button = $Web_CanvasLayer/Web_Menu/MarginContainer/PanelContainer/VBoxContainer/HBoxContainer/PanelContainer/VBoxContainer/Get_Web_News_Button

var news : Dictionary = {}
var past_feedback : Dictionary = {}
var choice_button_text = ""
var feedback_text = ""



func _ready():
	
	if permit_web_requests:
		permit_web_requests_button.pressed = true
	else:
		permit_web_requests_button.pressed = false
		
	feedback_text = feedback_text_node.text
	
	news_text_node.text = news.get("text", "")
	
	http_news.connect("request_completed", self, "_on_NEWS_HTTPRequest_completed")
	http_forms.connect("request_completed", self, "_on_FORMS_HTTPRequest_completed")
	http_images.connect("request_completed", self, "_on_IMAGES_HTTPRequest_completed")
	connect("web_news_update_received", self, "_on_web_news_update_received")
	
	

func _process(delta):
	timeout += delta
	if timeout >= timeout_threshold:
		timeout = 0
		reset_request_buttons()
		
		

func get_news_data():
	
	### if we requested news earlier don't make a new request until interval is up except for debug
	if OS.is_debug_build():
		pass
	elif ( OS.get_unix_time() < last_news_request_time + (NEWS_CHECK_INTERVAL_DAYS * 86400) ):
		return
	
	http_news.request(news_json_file_url)
	
	

func send_form_data():
	
	feedback_text = feedback_text_node.text
	if feedback_text == "":
		send_form_button.text = "No Input"
		yield(get_tree().create_timer(0.5), "timeout")
		reset_request_buttons()
		return
		
	### you find the entry keys for your form by creating a prefill form with a shareable link and than look at the url with all the entry pairs
	var form_data_to_send = {"entry.1591633300" : choice_button_text, "entry.154816542" : feedback_text}
	var _headers = ["Content-Type: application/x-www-form-urlencoded"]
	
	var http = HTTPClient.new()
	
	### change the data into a postable form
	var _headers_pool = PoolStringArray(_headers)
	var _form_data_to_send = http.query_string_from_dict(form_data_to_send)
	
	### Send the data to the web form
	http_forms.request(web_form_url, _headers_pool, false, http.METHOD_POST, _form_data_to_send)

	
	
func _on_Get_Web_News_Button_pressed():
	
	if permit_web_requests:
		timeout = 0
		set_process(true)
		get_news_button.disabled = true
		get_news_button.text = "Requesting ..."
		get_news_data()



func _on_Send_Form_Button_pressed():
	
	if permit_web_requests:
		timeout = 0
		set_process(true)
		send_form_button.disabled = true
		send_form_button.text = "Sending ..."
		send_form_data()



func _on_NEWS_HTTPRequest_completed( _result, _response_code, _headers, _body ):
	
	if _result == 0:
		var json = JSON.parse(_body.get_string_from_utf8())
		
		### save and update our news dictionary always, text is cheap and maybe we wanted to fix some typos
		news = json.result
		
		### check if we have news that are newer than the saved one
		
		if current_news_id < news.get("news_id", 0):# or OS.is_debug_build():
			
			current_news_id = news.get("news_id", 0)
			
			### request the new image from the news url from the web server
			if news.get("image"):
				http_images.request(news.get("image"))
			
			### alert that we have new news that we havn't read by now
			unread_news = true
			emit_signal("web_news_update_received")
			
			### save the time from our last request and the news in our persistent file
			last_news_request_time = OS.get_unix_time()
			game.save_persistent()
						
		get_news_button.text = "Sucess!"
		yield(get_tree().create_timer(0.5), "timeout")
		
		if OS.is_debug_build():
			print("successful loaded json news file from web")
		
	else:
		if OS.is_debug_build():
			print("failed to request json news file from web, error_code: %s" % _result)
			
	reset_request_buttons()
	
	
	
func reset_request_buttons():
	set_process(false)
	get_news_button.disabled = false
	get_news_button.text = "Get Web News"	
	send_form_button.disabled = false
	send_form_button.text = "Send Form Data"
	
	
	
func _on_FORMS_HTTPRequest_completed( _result, _response_code, _headers, _body ):

	if _result == 0:

		emit_signal("web_forms_update_received")
		
		last_send_feedback_time = OS.get_unix_time()
		past_feedback[OS.get_unix_time()] = feedback_text
		game.save_persistent()
		
		send_form_button.text = "Sucess!"
		yield(get_tree().create_timer(0.5), "timeout")
		feedback_text_node.text = ""
		
		if OS.is_debug_build():
			print("successful uploaded form data to web")
	else:
		if OS.is_debug_build():
			print("failed to uploaded form data to web, error_code: %s" % _result)
	
	reset_request_buttons()



func _on_IMAGES_HTTPRequest_completed( _result, _response_code, _headers, _body ):
	
	if _result == 0:
		
		var image = Image.new()
		
		
		### test if the image is a jpg, png or webp and try to load
		var image_error
		image_error = image.load_jpg_from_buffer(_body)
		if image_error != OK:
			print("image not jpg")
			image_error = image.load_png_from_buffer(_body)
			if image_error != OK:
				print("image not png")
				image_error = image.load_webp_from_buffer(_body)
				if image_error != OK:
					print("image not webp")
					
		if image_error != OK:
			print("error loading the file format for displaying the image.")
			return
			
		### save the news_image for further use until replaced
		var save_image_name = "user://persistent/news_image.png"
		image.save_png(save_image_name)

		
		### update the news image with the new texture
		var texture = ImageTexture.new()
		texture.create_from_image(image)
		news_image.texture = texture
	
	else:
		if OS.is_debug_build():
			print("error_code '%s' requesting web image" % _result)



func _on_Check_Web_Requests_pressed():
	if permit_web_requests:
		permit_web_requests_button.pressed = false
		permit_web_requests = false
	else:
		permit_web_requests_button.pressed = true
		permit_web_requests = true



func _on_CheckBox_Feedback_pressed():
	choice_button_text = "Comments"
	choice1_button.pressed = true
	choice2_button.pressed = false
	choice3_button.pressed = false

func _on_CheckBox_Bugreport_pressed():
	choice_button_text = "Bug+Reports"
	choice1_button.pressed = false
	choice2_button.pressed = true
	choice3_button.pressed = false

func _on_CheckBox_Question_pressed():
	choice_button_text = "Questions"
	choice1_button.pressed = false
	choice2_button.pressed = false
	choice3_button.pressed = true



func _on_web_news_update_received():
	news_text_node.text = news.get("text")



const SAVE_KEY = "WEB"

func save(save_game : Resource):
	#print(SAVE_KEY+" saved")
	save_game.data[SAVE_KEY] = {
		'news' : news,
		'last_news_request_time' : last_news_request_time,
		'last_send_feedback_time' : last_send_feedback_time,
		'permit_web_requests' : permit_web_requests,
		'past_feedback' : past_feedback,
		'current_news_id' : current_news_id
	}


func load(save_game : Resource):
	#print(SAVE_KEY+" loaded")
	var data : Dictionary = save_game.data[SAVE_KEY]
	news = data.get('news', {})
	last_news_request_time = data.get('last_news_request_time', 0)
	last_send_feedback_time = data.get('last_send_feedback_time', 0)
	permit_web_requests = data.get("permit_web_requests")
	past_feedback = data.get("past_feedback", {})
	current_news_id = data.get("current_news_id")
