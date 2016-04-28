//
//  ViewController.swift
//  VoiceChanger
//
//  Created by appsgaga on 2015/11/11.
//  Copyright © 2015年 appsgaga. All rights reserved.
//

import UIKit
import AVFoundation
class ViewController: UIViewController, AVAudioRecorderDelegate {
//為了判別是哪個button，所以給button、slider各自標上tag1~8
    @IBOutlet weak var myButton5: UIButton!//紅色錄音鈕的outlet
    
    @IBOutlet weak var myButton6: UIButton!//暫停錄音鈕的outlet(與紅色錄音鈕重疊),一開始要先把暫停的按鈕隱藏起來(回到mainStoryBoard選hidden)，指要顯示紅色錄音鈕。等到錄音時，在顯現暫停鈕
    
    @IBOutlet weak var mySlider1: UISlider!//調整echo、delay、reverb(模糊)效果，只會有這三種效果
    
    @IBOutlet weak var mySlider2: UISlider!//調整效果的量(左0右1，越往右效果越強)
    
    
    @IBOutlet weak var recordingImage: UIImageView!//一開始位於畫面正中央，且是隱藏的，等到錄音時會顯現出來，擋住四顆變音按鈕，並告訴使用者現在正在錄音，等到按下暫停鈕後會在隱藏。
    var myPlayer:AVAudioPlayer!//等等要用來播放聲音
    var audioRecorder:AVAudioRecorder!//等等要用來錄製聲音
    var audioEngine:AVAudioEngine!//等等要將錄製的聲音和特效連結
    var audioFile:AVAudioFile!//用來準備儲存做效果的聲音
    var isRecording:Bool = false//用來判斷是否正在錄音
    
    @IBAction func playAudio(sender: UIButton) {//因為button1~4一按下去，需要播放聲音，所以會觸發playAudio func()
        if isRecording == false{
            myPlayer.stop()
            myPlayer.currentTime = 0.0
            //以上兩行程式碼是避免播放音檔播到一半會出現錯誤
            if sender.tag == 1{
                myPlayer.rate = 3//加快播放的速度
                myPlayer.play()
            
            }else if sender.tag == 2{
                myPlayer.rate = 0.25//調慢播放速度
                myPlayer.play()
            
            }else if sender.tag == 3{//因為是調整pitch的button，所以要在下面另外寫個playAudioWithPitch func()
                playAudioWithPitch()
                
            }else if sender.tag == 4{//此button是針對slider調整的值的大小來變動音效，要在下面另外寫個playWithEffect func()
                playWithEffect()
            }
        }
    }
    func playAudioWithPitch(){
        myPlayer.stop()//停止播放音樂
        audioEngine.stop()//停止之前的效果
        audioEngine.reset()//把效果重置
        //接下來做調高音高的功能
        let audioPlayerNode = AVAudioPlayerNode()//生成一個AVAudioPlayerNode物件，並存放到audioPlayer常數(這是為了要連接特殊效果所使用的class)
        audioEngine.attachNode(audioPlayerNode)//把處理音檔的audioEngine連接處理特效的audioPlayerNode
        //以下再把想改的特效寫出來
        let addEffectPitch = AVAudioUnitTimePitch()//生成AVAudioUnitTimePitch的object
        addEffectPitch.pitch = 1800//預設是1，max值是2400，min值是-2400
        audioEngine.attachNode(addEffectPitch)//將調整因高的效果連結到audioEngine
        audioEngine.connect(audioPlayerNode, to: addEffectPitch, format: nil)//先將audioPlayerNode連結到addEffectPitch的效果
        audioEngine.connect(addEffectPitch, to: audioEngine.outputNode, format: nil)//再把加入效果後的聲音連結到output(輸出)
        audioPlayerNode.scheduleFile(audioFile, atTime: nil, completionHandler: nil)//這樣就放入音檔
        do{
            try audioEngine.start()//啟動audioEngine
        }catch _ {//若有錯誤的話什麼都不動
        }
        audioPlayerNode.play()//就會開始播放加入特效後的音樂了

    }
    
    @IBAction func stopAudio(sender: UIButton) {//當user停止按壓按鈕時，便會停止聲音的播放。(這個button事件為touch up inside)
        myPlayer.stop()
        myPlayer.currentTime = 0.0
        audioEngine.stop()
        audioEngine.reset()
    }
    
    @IBAction func recordAudio(sender: UIButton) {//錄音按鈕，按下去會錄音
        recordingImage.hidden = false//按下錄音鍵就把recordingImage顯現出來
        myButton5.hidden = true//再把錄音鍵隱藏起來
        myButton6.hidden = false//再把暫停鍵秀出來
        //以下是錄音的程式碼
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]//這用來設定錄音存檔的地方，第一個參數是設定存在電腦中Document的資料夾
        let recordingName = "User.wav"//這用來設定錄音後要存檔的檔名
        let pathArray = [dirPath , recordingName]//把檔名和資料夾包在一個array中
        let filePath = NSURL.fileURLWithPathComponents(pathArray)//利用包含檔名和資料夾的pathArray，便得到錄音後要存檔的完整路徑的URL
        let session = AVAudioSession.sharedInstance()//每個程式裡面都有一個音訊的工作階段AudioSession
        do{
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)//在錄音以前，需把這個session的狀態調整成PalyAndRecord的狀態，這樣設定已後，錄音的音量會比較正常
        }catch _ {
        }
        
        let recordSettings = [//設定錄音的品質
            AVEncoderAudioQualityKey:AVAudioQuality.Min.rawValue,
            AVEncoderBitRateKey:16,
            AVNumberOfChannelsKey:2,
            AVSampleRateKey:44100.0
        ]
        do{
            audioRecorder = try AVAudioRecorder(URL: filePath!, settings: recordSettings as! [String:AnyObject])//生成AVAudioRecorder的實體
            audioRecorder?.delegate = self//將viewController指定給audioRecorder?.delegate，這樣錄完音後就可以透過audioRecorderDidFinishRecording func()去做錄完音後要做的後續處理
        }catch _{
            audioRecorder = nil
        }
        //接下來是開始錄音的程式碼
        audioRecorder?.prepareToRecord()
        audioRecorder?.record()
        isRecording = true
    }
    
    @IBAction func stopRecord(sender: UIButton) {//暫停按鈕，按下會停止錄音
        recordingImage.hidden = true //按下暫停鍵就把recordingImage隱藏起來
        myButton5.hidden = false //再把錄音鍵秀起來
        myButton6.hidden = true //再把暫停鍵隱藏出來
        //以下是暫停錄音的程式碼
        if audioRecorder != nil{
            audioRecorder!.stop()//除了將record stop,還要調整程式seesion的狀態成Playback
            isRecording = false
            let audioSeesion = AVAudioSession.sharedInstance()
            do{
                try audioSeesion.setCategory(AVAudioSessionCategoryPlayback)//seesion的狀態成Playback，這樣以後才能用正常的音量播放錄好的聲音
                
            }catch _{
            }
            
            do{
                try audioSeesion.setActive(false)
            }catch _{
            }
            
        }

    }
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {//兩個參數，recorder代表錄音的audioRecorder; flag代表錄音是否成功
       myPlayer = try? AVAudioPlayer(contentsOfURL: recorder.url)//用recorder.url這個url生成AVAudioPlayer物件，並存在myPlayer，以供後續聲音的播放
        myPlayer.enableRate = true//允許調整聲音速度
        audioFile = try? AVAudioFile(forReading: recorder.url)//用recorder.url生出AVAudioFile物件，應存回audioFile，以供後續做效果的播放
    }
    

    
    @IBAction func mySliderValueChange(sender: UISlider) {//user調整第一個slider的話，會觸發此func()。同時也連結了recording img到這個func()
        var newValue = sender.value
        if newValue > 0.66{//先設定滑桿的數值只會在0\0.5\1停下來(分別代表3種不同的特效echo\delay\reverb)
            newValue = 1
        }else if newValue > 0.33{
            newValue = 0.5
        }else{
            newValue = 0
        }
        mySlider1.value = newValue
    }
    
    override func viewWillAppear(animated: Bool) {
        mySlider1.value = 0//希望每次到這畫面時，預先將滑桿推至最左
        mySlider2.value = 1//預先將滑桿推至最右
    }
    
    func playWithEffect(){
        myPlayer.stop()
        audioEngine.stop()
        audioEngine.reset()
        var effectType = 3//有3種效果(echo/delay/reverb)
        if mySlider1.value == 1{
            effectType = 3
        }else if mySlider1.value == 0.5{
            effectType = 2
        }else if mySlider1.value == 0{
            effectType = 1
        }
        
        let effectValue = mySlider2.value * 100//決定要放入多少量的效果(看slider2的數值決定)
        
        let audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attachNode(audioPlayerNode)
        //下面再根據effectType決定要生成哪一個不同的特效object
        if effectType == 1{//第一種echo效果
            let distortionEffect = AVAudioUnitDistortion()//echo效果的物件
            distortionEffect.loadFactoryPreset(.MultiEcho2)//這樣就可以調用MultiEcho2的效果
            distortionEffect.wetDryMix = effectValue//wetDryMix屬性負責調整效果的量
            audioEngine.attachNode(distortionEffect)//連接各個元件
            audioEngine.connect(audioPlayerNode, to: distortionEffect, format: nil)
            audioEngine.connect(distortionEffect, to: audioEngine.outputNode, format: nil)
        }else if effectType == 2{//第二種delay效果
            let delayEffect = AVAudioUnitDelay()
            delayEffect.delayTime = Double(mySlider2.value)//這邊的delay time需要一個Double的數值，所以要把它轉成double的數值
            delayEffect.wetDryMix = 100
            audioEngine.attachNode(delayEffect)//連接各個元件
            audioEngine.connect(audioPlayerNode, to: delayEffect, format: nil)
            audioEngine.connect(delayEffect, to: audioEngine.outputNode, format: nil)
        }else{//第一種reverb效果
            let reverbEffect = AVAudioUnitReverb()
            reverbEffect.loadFactoryPreset(.Cathedral)//用大教堂(.Cathedral)回音的效果
            reverbEffect.wetDryMix = effectValue
            audioEngine.attachNode(reverbEffect)//連接各個元件
            audioEngine.connect(audioPlayerNode, to: reverbEffect, format: nil)
            audioEngine.connect(reverbEffect, to: audioEngine.outputNode, format: nil)
        }
        audioPlayerNode.scheduleFile(audioFile, atTime: nil, completionHandler: nil)//把audioFile讀入
        do{
            try audioEngine.start()
        }catch _{
            
        }
        audioPlayerNode.play()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let sliderImg = UIImage(named: "SliderPin")
        let scaleImg = imageWithImage( sliderImg!, newSize: CGSizeMake(21, 37))//用剛剛寫的func，將圖片調整成寬度為21,高度為37的圖片
        mySlider1.setThumbImage(scaleImg, forState: .Normal)//如此可以更改slider滑桿的圖
        mySlider2.setThumbImage(scaleImg, forState: .Normal)//如此可以更改slider滑桿的圖
        //接著再回到mainStoryBoard將滑桿的min/max track tint的color，改為clear color，這樣線就會消失
        //再生出各個物件
        let path = NSBundle.mainBundle().pathForResource("Areyouready", ofType: "m4a")
        
        myPlayer = try? AVAudioPlayer(contentsOfURL: NSURL.fileURLWithPath(path!))//用path生出一個url，再用url生出一個AVAudioPlayer
        myPlayer.enableRate = true //等等程式會調整播放音檔的速度
        
        audioEngine = AVAudioEngine()//生出AVAudioEngine object，並存在audioEngie屬性
        audioFile = try! AVAudioFile(forReading: NSURL.fileURLWithPath(path!))//是用path生出一個url，再用一個url生出一個AVAudioFile
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func imageWithImage(image:UIImage,newSize:CGSize) -> UIImage{//這是用來調整圖像大小用的，給一張image;還有newSize希望的大小後，便會回傳調整成希望大小的UIImage圖片
        UIGraphicsBeginImageContext(newSize)
        image.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

