import UIKit
import Photos

@objc(CDVDocumentPicker)
class CDVDocumentPicker : CDVPlugin {
    var commandCallback: String?
    
    @objc(getFile:)
    func getFile(command: CDVInvokedUrlCommand) {
        DispatchQueue.global(qos: .background).async {
			//srcType:PHOTOLIBRARY,  SAVEDPHOTOALBUM, DOCUMENT
			//fileTypes: 可是以单个字符串或数组
			//title:   弹出框的Title,IOS不需要
            var srcType: String  = ""
            var fileTypes: [String] = []
			self.commandCallback = command.callbackId
            
			if command.arguments.isEmpty || command.arguments.count < 2{
				self.sendError("Didn't receive all arguments.")
			} else {
                if( command.arguments[0] as? String != nil){
                    srcType = command.arguments[0] as! String
                     if  srcType != "PHOTOLIBRARY" && srcType  != "SAVEDPHOTOALBUM" && srcType  != "DOCUMENT" {
                        srcType = "DOCUMENT"
                    }
                }
                
                if let key = command.arguments[1] as? String {
                    let type  = self.formatDocType(fileType: key)
                    fileTypes.append(type)
                } else if let array = command.arguments[1] as? [String] {
                    fileTypes = array.compactMap { self.formatDocType(fileType: $0) }
                }

				if fileTypes.isEmpty {
                    fileTypes.append("*/*")
					//self.sendError("Didn't receive any filetypes argument.")
				}
					
                if srcType == "DOCUMENT" {
                    self.callPicker(withTypes: fileTypes)
                } else {
                    self.callImagePicker(srcType:srcType, withTypes: fileTypes)
                }
				
			}
        }
    }
    
	func formatDocType(fileType: String) -> String {
        switch fileType {
			case "*/*":
				return "public.data"
			case "video/*":
				return "public.movie"
			case "video/mp4":
				return "public.mpeg-4"
			case "video/avi":
				return "public.avi"				
			case "image/*":
				return "public.image"
			case "image/gif":
				return "com.compuserve.gif"
			case "image/jpeg":
				return "public.jpeg"
			case "image/png":
				return "public.png"
			case "audio/*":
				return "public.audio"
			case "audio/mp3":
				return "public.mp3"
			case "application/pdf", "pdf":
				return "com.adobe.pdf"
			case "application/msword", "doc":
				return "com.microsoft.word.doc"
			case "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "docx":
				return "org.openxmlformats.wordprocessingml.document"
			case "application/vnd.ms-excel", "xls":
				return "com.microsoft.excel.xls"
			case "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "xlsx":
				return "org.openxmlformats.spreadsheetml.sheet"
			case "application/mspowerpoint", "ppt":
				return "com.microsoft.powerpoint.​ppt"
			case "application/vnd.openxmlformats-officedocument.presentationml.presentation", "pptx":
				return "org.openxmlformats.presentationml.presentation"
			default:
				return fileType
		}	
	}
	
    func callPicker(withTypes documentTypes: [String]) {
	
        DispatchQueue.main.async {

            let picker = UIDocumentPickerViewController(documentTypes: documentTypes, in: .open)  //.import
            picker.delegate = self
            if #available(iOS 11.0, *) {
                picker.allowsMultipleSelection = false
            } else {
                // Fallback on earlier versions
            };

            self.viewController.present(picker, animated: true, completion: nil)
        }
    }
	
    func callImagePicker(srcType: String, withTypes documentTypes: [String]) {

        DispatchQueue.main.async {
			let imagePickerController = UIImagePickerController()
			//设置代理
			imagePickerController.delegate = self
			//允许用户对选择的图片或影片进行编辑
			imagePickerController.allowsEditing = false
			//设置image picker的用户界面
			imagePickerController.sourceType = srcType == "PHOTOLIBRARY" ? .photoLibrary : .savedPhotosAlbum //或者.savedPhotosAlbum
			imagePickerController.mediaTypes =  documentTypes   //[kUTTypeMovie as String]
			//设置图片选择控制器导航栏的背景颜色
		  //  imagePickerController.navigationBar.barTintColor = UIColor.orange
			//设置图片选择控制器导航栏的标题颜色
		 //   imagePickerController.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
			//设置图片选择控制器导航栏中按钮的文字颜色
		//    imagePickerController.navigationBar.tintColor = UIColor.white
			//显示图片选择控制器
            self.viewController.present(imagePickerController, animated: true, completion: nil)

        }
    }
	
    func documentWasSelected(document: URL) {
        self.sendResult(.init(status: CDVCommandStatus_OK, messageAs: document.absoluteString))
        self.commandCallback = nil
    }

    func sendError(_ message: String) {
        sendResult(.init(status: CDVCommandStatus_ERROR, messageAs: message))
    }

}

private extension CDVDocumentPicker {
    func sendResult(_ result: CDVPluginResult) {

        self.commandDelegate.send(
            result,
            callbackId: commandCallback
        )
    }
}

extension CDVDocumentPicker: UIDocumentPickerDelegate {

    @available(iOS 11.0, *)
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            documentWasSelected(document: url)
        }
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL){
        documentWasSelected(document: url)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        sendError("User canceled.")
    }
}

extension CDVDocumentPicker: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
  //选择图片成功后代理
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
 
        //选择图片的引用路径
        var pickedURL = info["UIImagePickerControllerImageURL"] as? URL
        if pickedURL == nil {
            pickedURL =  info["UIImagePickerControllerMediaURL"] as? URL
        }
        if pickedURL == nil {
             sendError("No File selected.")
        }
        self.documentWasSelected(document: pickedURL ?? info[UIImagePickerControllerMediaURL] as! URL)

        //图片控制器退出
        picker.dismiss(animated: true, completion:nil)
    }
     
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController){
	 //图片控制器退出
        picker.dismiss(animated: true, completion:nil)
		sendError("User canceled.")
	}
	
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//    }

}