@interface AVSpeechSynthesisVoice : NSObject
@property (nonatomic, copy) NSString *identifier;
+(AVSpeechSynthesisVoice *)_voiceWithIdentifier:(NSString *)identifier includingSiri:(bool)siri;
+(AVSpeechSynthesisVoice *)voiceWithLanguage:(NSString *)language;
@end

@interface AVSpeechUtterance : NSObject
@property (nonatomic, copy) AVSpeechSynthesisVoice *voice;
+(AVSpeechUtterance *)speechUtteranceWithString:(NSString *)string;
@end

@interface AVSpeechSynthesizer : NSObject
-(void)speakUtterance:(AVSpeechUtterance *)utterance;
@end

@interface SBAssistantController
+(id)sharedInstance;
-(void)handleSiriButtonUpEventFromSource:(int)arg1;
-(bool)handleSiriButtonDownEventFromSource:(int)arg1 activationEvent:(int)arg2;
@end

AVSpeechSynthesisVoice *voice;
int presses;
bool running;

void sayTime(){
	dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
	running = true;
	if(presses == 2)
		[NSThread sleepForTimeInterval:0.75];
	    if(presses == 2){
	    	dispatch_async(dispatch_get_main_queue(), ^(void){
	    		NSDate *date = [NSDate date];
				NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setDateFormat:@"hh:mm a"];
				NSString *formattedDateString = [dateFormatter stringFromDate:date];
				NSString *newFormattedDateString = [NSString stringWithFormat:@"It's %@", formattedDateString];
				AVSpeechSynthesizer *synthesizer = [[%c(AVSpeechSynthesizer) alloc] init];
				AVSpeechUtterance *utterance = [%c(AVSpeechUtterance) speechUtteranceWithString:newFormattedDateString];
				//utterance.voice = [%c(AVSpeechSynthesisVoice) voiceWithLanguage:/*[NSLocale preferredLanguages][0]*/@"en-UK"];
				utterance.voice = voice;
				[synthesizer speakUtterance:utterance];
				if(@available(iOS 12, *)){
					voice.identifier = @"com.apple.ttsbundle.gryphon_female_en-US_premium";
				}
				presses = 0;
				running = false;
			});
		}
		else{
			dispatch_async(dispatch_get_main_queue(), ^(void){
				SBAssistantController *assistantController = [%c(SBAssistantController) sharedInstance];
        		[assistantController handleSiriButtonDownEventFromSource:1 activationEvent:1];
        		[assistantController handleSiriButtonUpEventFromSource:1];
				presses = 0;
				running = false;
			});
		}
	});
}

%hook BluetoothManager
-(void)_postNotificationWithArray:(NSArray *)array{
	NSLog(@"-[BluetoothManager _postNotificationWithArray:]\n%@", array);
	bool isVoice;
	for(NSString *string in array){
		if([string respondsToSelector:@selector(isEqualToString:)]){
			if([string isEqualToString:@"BluetoothHandsfreeInitiatedVoiceCommand"] || [string isEqualToString:@"BluetoothHandsfreeEndedVoiceCommand"]){
				isVoice = true;
			}
		}
	}
	if(isVoice){
		if(presses == 0)
			presses = 2;
		else if(presses == 2)
			presses = 4;
		else if(presses == 4)
			presses = 0;
		if(!running)
			sayTime();
	}
	else{
		%orig();
	}
}
%end

%ctor{
	presses = 0;
	if(@available(iOS 12, *)){
		voice = [%c(AVSpeechSynthesisVoice) _voiceWithIdentifier:@"com.apple.ttsbundle.gryphon_female_en-US_premium" includingSiri:YES];
	}
	else{
		voice = [%c(AVSpeechSynthesisVoice) voiceWithLanguage:[NSLocale preferredLanguages][0]];
	}
}