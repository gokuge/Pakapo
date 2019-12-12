//
//  PakapoImageModel.swift
//  Pakapo
//
//  Created by gokuge on 2019/12/06.
//  Copyright © 2019 gokuge. All rights reserved.
//

import Cocoa

class PakapoImageModel: NSObject {
    
    let ROOT_DIRECTORY_URL: String = "rootDirectoryURL"
    let LAST_PAGE_URL: String = "lastPageURL"
    var isSearchChild: Bool!
    
    var rootDirURL: URL?
    var rootDirectories: [URL]?
    var currentDirURL: URL?
    
    var fileContents: [URL]?
    var fileContentsIndex: Int?

    var dirContents: [URL]?
    var lastDisplayChildDirURL: URL?
    
    public override init() {
        super.init()
        if let root = loadRootDirectoryURL() {
            rootDirURL = root
        }
    }
    
    // MARK: - UserDefault
    func saveRootDirectoryURL(root: URL) -> Bool {
        var isDir: ObjCBool = false
        if !FileManager.default.fileExists(atPath: root.path, isDirectory: &isDir) {
            //指定したURLが存在しないってことはこのタイミングではないはず
            return false
        }
        
        /*
            ## 基本動作：末端のdirectoryを内包するdirectoryをrootとする
            - 引数のURLがfile/directoryで処理が変わる
                - /tmp/hoge/fuga.jpgの場合はtmpがroot
                - /tmp/hoge/の場合はtmpがroot
            - /Usersの様な場所で選択された場合、削除せず選択された所をrootとする(component.count == 2)
         */

        var saveURL = root
        
        let component = root.pathComponents

        if component.count < 2 {
            //そんな所で選択しないでくれガード
            return false
        } else if component.count > 2 {
            saveURL = saveURL.deletingLastPathComponent()
            
            if !isDir.boolValue {
                saveURL = saveURL.deletingLastPathComponent()
            }
        }
                
        UserDefaults.standard.set(saveURL, forKey: ROOT_DIRECTORY_URL)
        rootDirURL = saveURL
        return true
    }
    
    func loadRootDirectoryURL() -> URL? {
        guard let unwrappedURL = UserDefaults.standard.url(forKey: ROOT_DIRECTORY_URL) else {
            return nil
        }
        
        return unwrappedURL
    }
    
    func initRootSameDirectories() -> (currentIndex: Int?, directories: [URL]?) {
        guard let unwrappedRootDirURL = rootDirURL,
              let unwrappedCurrentDirURL = currentDirURL else {
            return(nil, nil)
        }

        //root直下のdirectoryを確保したいので一旦rootでrefresh
        refreshContents(dirURL: unwrappedRootDirURL)
        
        //rootのdirectoryを退避
        rootDirectories = dirContents
        
        //元の位置でrefresh
        refreshContents(dirURL: unwrappedCurrentDirURL)
        
        guard let unwrappedTmpRootDirectories = rootDirectories else {
            return (nil, nil)
        }
        
        //rootとcurrentが一致していた場合、チェックをつけるべきdirectoryはなし
        if unwrappedRootDirURL.absoluteString == unwrappedCurrentDirURL.absoluteString {
            return (nil, unwrappedTmpRootDirectories)
        }
        
        for (currentIndex, dirURL) in unwrappedTmpRootDirectories.enumerated() {
            if unwrappedCurrentDirURL.absoluteString.hasPrefix(dirURL.absoluteString) {
                return (currentIndex, unwrappedTmpRootDirectories)
            }
        }
        
        return (nil, nil)
    }
    
    func getFileURL() -> URL? {
        guard let unwrappedFileContentsIndex = fileContentsIndex,
              let unwrappedFileContents = fileContents else {
            return nil
        }
        
        guard unwrappedFileContents.indices.contains(unwrappedFileContentsIndex) else {
            return nil
        }
        
        return unwrappedFileContents[unwrappedFileContentsIndex]
    }
    
    func saveFileURL() {
        guard let fileURL = getFileURL() else {
            return
        }

        UserDefaults.standard.set(fileURL, forKey: LAST_PAGE_URL)
    }
    
    func loadFileURL() -> URL? {
        guard let unwrappedURL = UserDefaults.standard.url(forKey: LAST_PAGE_URL) else {
            return nil
        }
        
        return unwrappedURL
    }

    // MARK: -
    func loadPageTitle() -> String {
        guard let unwrappedCurrentDirURL = currentDirURL else {
            return ""
        }
        let component = unwrappedCurrentDirURL.pathComponents
        
        return component[component.count - 1]
    }
    
    func refreshContents(dirURL: URL) {
        do {
            /*
                ## 基本動作
                - 名前順
                - 現在のdirectoryのfile表示を最優先とする
                - 現在のdirectoryの全てのfileが表示された = 終点に来た場合、子directoryが存在するかどうかで挙動をかえる
                    - 存在するなら子directoryの中身を表示させていく
                    - 存在しないなら自分の親のdirectoryへ戻り、自分の次の子のdirectoryの中身を表示させていく
             */


            let contentUrls = try FileManager.default.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil)
            let sortContens = contentUrls.sorted { a, b in
                return a.lastPathComponent.localizedStandardCompare(b.lastPathComponent) == ComparisonResult.orderedAscending
            }

            fileContents = []
            dirContents = []

            for content in sortContens {
                
                //隠しfileは除外
                if content.lastPathComponent.hasPrefix(".") {
                    continue
                }
                
                var isDir: ObjCBool = false
                if !FileManager.default.fileExists(atPath: content.path, isDirectory: &isDir) {
                    //指定したURLが存在しないってことはこのタイミングではないはず
                    continue
                }
                
                if isDir.boolValue {
                    //dir
                    dirContents!.append(content)
                } else {
                    //file
                    fileContents!.append(content)
                }
            }
            
            if dirContents!.count == 0 {
                dirContents = nil
            }
            
            if fileContents!.count == 0 {
                fileContents = nil
            }
            
            currentDirURL = dirURL
            
        } catch {
            //Permissionでコケる場合がある
            print(error)
        }
    }

    // MARK: - image
    func loadInitImage(contentURL: URL) -> NSImage? {
        var isDir: ObjCBool = false
        if !FileManager.default.fileExists(atPath: contentURL.path, isDirectory: &isDir) {
            //指定したURLが存在しないってことはこのタイミングではないはず
            return nil
        }

        if isDir.boolValue {
            //dir内でContentsを作成
            refreshContents(dirURL: contentURL)
            
            return loadValidImage(contents: fileContents)
        } else {
            //fileが入っているdir内のContentsを作成
            refreshContents(dirURL: contentURL.deletingLastPathComponent())
            
            guard let unwrappedFileContents = fileContents else {
                return nil
            }

            //indexの更新
            fileContentsIndex = unwrappedFileContents.firstIndex(of: contentURL)
            
            guard let unwrappedImage = NSImage(contentsOf: contentURL) else {
                return nil
            }
            
            return unwrappedImage
        }
    }
    
    func loadValidImage(contents: [URL]?) -> NSImage? {
        guard let unwrappedContents = contents else {
            return nil
        }
        
        //indexの更新
        for (index, content) in unwrappedContents.enumerated() {
            fileContentsIndex = index
            guard let unwrappedImage = NSImage(contentsOf: content) else {
                continue
            }
            
            return unwrappedImage
        }

        return nil
    }
    
    func loadNextImage() -> NSImage? {
        guard var unwrappedFileContentsIndex = fileContentsIndex,
              let unwrappedCurrentDirURL = currentDirURL,
              let unwrappedRootDirURL = rootDirURL else {
            return nil
        }
        
        var isEnd: Bool = false
        
        if let unwrappedFileContens = fileContents {
            if unwrappedFileContentsIndex == unwrappedFileContens.count - 1 {
                isEnd = true
            }
        } else {
            //CurrentDirにfileがない
            isEnd = true
        }
                
        if isEnd {
            //終点。次の有効directoryを探す
            if let validDirURL = loadChildNextDirectory(dirURL: unwrappedCurrentDirURL) {
                //currentに次の有効directoryあり
                refreshContents(dirURL: validDirURL)
            } else if let validDirURL = loadNextValidDirectory(dirURL: unwrappedCurrentDirURL){
                //親へ遡り、次の有効directoryを発見した
                refreshContents(dirURL: validDirURL)
            } else {
                //次の有効directoryが無い。rootで更新する。
                refreshContents(dirURL: unwrappedRootDirURL)
                
                lastDisplayChildDirURL = nil
                
                //rootに有効なfileがない場合は子供の検索
                if fileContents == nil {
                    guard let validURL = loadChildNextDirectory(dirURL: unwrappedRootDirURL) else {
                        //rootから子供にいたるまで表示可能なcontentがない。openしてもらうしかない
                        return nil
                    }
                    
                    refreshContents(dirURL: validURL)
                }

            }

            lastDisplayChildDirURL = nil
            unwrappedFileContentsIndex = 0
            
        } else {
            //まだ終点じゃない
            unwrappedFileContentsIndex += 1
        }
        
        fileContentsIndex = unwrappedFileContentsIndex
        
        guard let fileURL = getFileURL() else {
            return nil
        }
        
        return NSImage(contentsOf: fileURL)
    }
    
    func loadPrevImage() -> NSImage? {
        guard var unwrappedFileContentsIndex = fileContentsIndex,
              let unwrappedCurrentDirURL = currentDirURL,
              let unwrappedRootDirURL = rootDirURL else {
            return nil
        }
        
        var isStart: Bool = false
        
        if fileContents != nil {
            if unwrappedFileContentsIndex == 0 {
                isStart = true
            }
        } else {
            //CurrentDirにfileがない
            isStart = true
        }
        
        if isStart {
            //始点。始点の時点でcurrentのdirectoryはもう検索する必要がないので、親に遡り有効ディレクトリを探す
            if let validDirURL = loadPrevValidDirectory(dirURL: unwrappedCurrentDirURL){
                //親へ遡り、次の有効directoryを発見した
                refreshContents(dirURL: validDirURL)
            } else {
                //次の有効directoryが無い。rootで更新する。
                refreshContents(dirURL: unwrappedRootDirURL)
                
                lastDisplayChildDirURL = nil
                
                //rootにdirectoryがある場合は子供の検索
                if dirContents != nil {
                    guard let validURL = loadChildPrevDirectory(dirURL: unwrappedRootDirURL) else {
                        //rootから子供にいたるまで表示可能なcontentがない。openしてもらうしかない
                        return nil
                    }
                    refreshContents(dirURL: validURL)
                }

            }
            
            lastDisplayChildDirURL = nil
            if let unwrappedFileContent = fileContents {
                unwrappedFileContentsIndex = unwrappedFileContent.count - 1
            } else  {
                unwrappedFileContentsIndex = 0
            }
        } else {
            //まだ始点じゃない
            unwrappedFileContentsIndex -= 1
        }

        fileContentsIndex = unwrappedFileContentsIndex
        
        guard let fileURL = getFileURL() else {
            return nil
        }
        
        return NSImage(contentsOf: fileURL)
    }
    
    // MARK: - directory
    func jumpSameDirectory(index: Int) -> NSImage? {
        guard let unwrappedRootDirectories = rootDirectories else {
            return nil
        }
        
        return jumpDirectory(url: unwrappedRootDirectories[index])
    }
    
    func jumpDirectory(url: URL) -> NSImage? {
        lastDisplayChildDirURL = nil
        
        return loadInitImage(contentURL: url)
    }
    
    func loadNextDirectory() -> NSImage? {
        guard let unwrappedFileContents = fileContents else {
            return nil
        }
        
        //現在のdirectoryの最後まで表示した事にして、後はloadNextImageに任せる
        fileContentsIndex = unwrappedFileContents.count - 1
        
        return loadNextImage()
    }
    
    func loadPrevDirectory() -> NSImage? {
        //現在のdirectoryの頭まで表示した事にして、一旦loadPrevImageを実行する
        fileContentsIndex = 0
        
        if loadPrevImage() == nil {
            return nil
        }
        
        //loadPrevImageは前のdirectoryの最後のindexを指す様にfileContentsIndexを変えてしまうので、頭を指す様にしておく
        fileContentsIndex = 0

        //loadPrevImageがnilじゃない時点で確実に表示出来るfileがある
        return NSImage(contentsOf: fileContents!.first!)
    }
    
    func makeNextSearchDirectory() -> [URL]? {
        guard var unwrappedDirContents = dirContents else {
            return nil
        }
        
        //以前directoryを調べた事があるならその時点まで持っていく
        
        guard let unwrappedLastDisplayChildDirURL = lastDisplayChildDirURL,
              let unwrappedLastDisplayChildDirIndex = unwrappedDirContents.firstIndex(of: unwrappedLastDisplayChildDirURL) else {
            //以前検索したDirectoryは無し。頭から調べる
            return unwrappedDirContents
        }
        
        if !unwrappedDirContents.indices.contains(unwrappedLastDisplayChildDirIndex + 1) {
            //現状のDirectoryではもう検索対象のDirectoryがない
            return nil
        }
        
        //次の検索対象となるDirectoryのみを返す
        unwrappedDirContents.removeSubrange(0...unwrappedLastDisplayChildDirIndex)
        return unwrappedDirContents
    }
    
    func makePrevSearchDirectory() -> [URL]? {
        guard var unwrappedDirContents = dirContents else {
            return nil
        }
        
        //以前directoryを調べた事があるならその位置まで持っていく
        
        guard let unwrappedLastDisplayChildDirURL = lastDisplayChildDirURL,
              let unwrappedLastDisplayChildDirIndex = unwrappedDirContents.firstIndex(of: unwrappedLastDisplayChildDirURL) else {
            //以前検索した子Directoryは無し。そのまま返す
            return unwrappedDirContents.reversed()
        }
        
        
        if !unwrappedDirContents.indices.contains(unwrappedLastDisplayChildDirIndex - 1) {
            //現状のDirectoryではもう検索対象のDirectoryがない
            return nil
        }
        
        //前に表示すべき子Directoryがある場合、自分自身から後を削除
        unwrappedDirContents.removeSubrange(unwrappedLastDisplayChildDirIndex...unwrappedDirContents.count - 1)

        return unwrappedDirContents.reversed()
    }
    
    func loadChildNextDirectory(dirURL: URL) -> URL? {
        if !isSearchChildDirectory() {
            return nil
        }
        
        guard let searchDirectories = makeNextSearchDirectory() else {
            return nil
        }
        
        for dir in searchDirectories {
            refreshContents(dirURL: dir)

            if loadValidImage(contents: fileContents) != nil {
                return dir
            }
            
            lastDisplayChildDirURL = dir
            guard let validURL = loadChildNextDirectory(dirURL: dir) else {
                continue
            }

            return validURL
        }

        return nil
    }
    
    func loadChildPrevDirectory(dirURL: URL) -> URL? {
        if !isSearchChildDirectory() {
            return nil
        }

        guard let searchDirectories = makePrevSearchDirectory() else {
            return nil
        }
        
        for dir in searchDirectories {
            
            refreshContents(dirURL: dir)

            if dirContents != nil {
                lastDisplayChildDirURL = dir
                if let validURL = loadChildPrevDirectory(dirURL: dir) {
                    return validURL
                }
            }
            
            guard let unwrappedFileContents = fileContents else {
                continue
            }
            
            if loadValidImage(contents: unwrappedFileContents.reversed()) != nil {
                return dir
            }
            
        }

        return nil
    }
    
    func isSearchChildDirectory() -> Bool {
        guard let unwrappedRootDirURL = rootDirURL,
              let unwrappedCurrentDirURL = currentDirURL else {
            return false
        }
        
        //rootの子は有効
        if unwrappedRootDirURL.absoluteString == unwrappedCurrentDirURL.absoluteString {
            return true
        }
        
        return isSearchChild
    }
    
    func loadNextValidDirectory(dirURL: URL) -> URL? {
        guard let unwrappedRootDirURL = rootDirURL else {
            return nil
        }
        
        //rootより親は検索対象にしない
        if unwrappedRootDirURL.absoluteString == dirURL.absoluteString {
            return nil
        }
        
        //現状表示しているURLを最後に表示させたURLとして確保しておく
        lastDisplayChildDirURL = dirURL
        
        let nextDirURL = dirURL.deletingLastPathComponent()

        //親でcontentを更新する
        refreshContents(dirURL: nextDirURL)
        
        guard let searchDirectories = makeNextSearchDirectory() else {
            //親に検索対象に出来るdirectoryが存在しなかった。更に親へ
            return loadNextValidDirectory(dirURL: nextDirURL)
        }
        
        for dir in searchDirectories {
            guard let validURL = loadChildNextDirectory(dirURL: dir) else {
                continue
            }
            
            return validURL
        }

        return nil
    }
    
    func loadPrevValidDirectory(dirURL: URL) -> URL? {
        guard let unwrappedRootDirURL = rootDirURL else {
            return nil
        }
        
        //rootより親は検索対象にしない
        if unwrappedRootDirURL.absoluteString == dirURL.absoluteString {
            return nil
        }
        
        //現状表示しているURLを最後に表示させたURLとして確保しておく
        lastDisplayChildDirURL = dirURL
        
        let nextDirURL = dirURL.deletingLastPathComponent()

        //親でcontentを更新する
        refreshContents(dirURL: nextDirURL)
        
        guard let searchDirectories = makePrevSearchDirectory() else {
            
            if let unwrappedFileContents = fileContents {
                return unwrappedFileContents.last?.deletingLastPathComponent()
            }
            
            //親に検索対象に出来るdirectoryが存在しなかった。更に親へ
            return loadPrevValidDirectory(dirURL: nextDirURL)
        }
        
        for dir in searchDirectories {
            guard let validURL = loadChildPrevDirectory(dirURL: dir) else {
                continue
            }
            
            return validURL
        }

        return nil
    }
}
