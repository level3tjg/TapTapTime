@interface AVSpeechSynthesisVoice : NSObject
@property (nonatomic, assign) NSInteger quality;
@property (nonatomic, copy) NSString *identifier;
+(AVSpeechSynthesisVoice *)_voiceWithIdentifier:(NSString *)identifier includingSiri:(bool)siri;
+(AVSpeechSynthesisVoice *)voiceWithIdentifier:(NSString *)identifier;
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
	running = true;
	dispatch_async(dispatch_get_main_queue(), ^{
    	[NSTimer scheduledTimerWithTimeInterval:0.75 repeats:NO block:^(NSTimer * _Nonnull timer){
    		if(presses == 2){
	    		NSDate *date = [NSDate date];
				NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setDateFormat:@"hh:mm a"];
				NSString *formattedDateString = [dateFormatter stringFromDate:date];
				NSString *newFormattedDateString = [NSString stringWithFormat:@"It's %@", formattedDateString];
				AVSpeechSynthesizer *synthesizer = [[%c(AVSpeechSynthesizer) alloc] init];
				AVSpeechUtterance *utterance = [%c(AVSpeechUtterance) speechUtteranceWithString:newFormattedDateString];
				utterance.voice = voice;
				[synthesizer speakUtterance:utterance];
				if(@available(iOS 12, *)){
					voice.identifier = @"com.apple.ttsbundle.gryphon_female_en-US_premium";
				}
				presses = 0;
				running = false;
			}
			else if(presses == 4){
				SBAssistantController *assistantController = [%c(SBAssistantController) sharedInstance];
        		[assistantController handleSiriButtonDownEventFromSource:1 activationEvent:1];
        		[assistantController handleSiriButtonUpEventFromSource:1];
				presses = 0;
				running = false;
			}
		}];
	});
}

%hook BluetoothManager
-(void)_postNotificationWithArray:(NSArray *)array{
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
		voice = [%c(AVSpeechSynthesisVoice) _voiceWithIdentifier:[NSString stringWithFormat:@"com.apple.ttsbundle.gryphon_female_%@_premium", [NSLocale preferredLanguages][0]] includingSiri:YES];
	}
	else{
		voice = [%c(AVSpeechSynthesisVoice) voiceWithLanguage:[NSLocale preferredLanguages][0]];
	}
	voice.quality = 3;
}