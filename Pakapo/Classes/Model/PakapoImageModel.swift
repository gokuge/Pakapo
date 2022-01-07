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
    let LAST_ZIP_DIRECTORY_URL: String = "lastZipDirectoryURL"
    let OPEN_RECENT_DIRECTORIES: String = "openRecentDirectories"
    let OPEN_RECENT_MAX_COUNT: Int = 10
    
    var rootDirURL: URL?
    var rootDirectories: [URL]?
    
    var currentDirURL: URL?
    
    var fileContents: [URL]?
    var fileContentsIndex: Int?

    var dirContents: [URL]?
    var lastSearchedDirURL: URL?

    var aliasMapperDic: [URL:URL] = [:]
    
    var zipContents: ZUnzip?
    var lastZipPageURL: URL?
    
    public override init() {
        super.init()
        if let root = getRootDirectoryURL() {
            rootDirURL = root
        }
    }

    // MARK: make
    func refreshContents(dirURL: URL) {
        if !isZipFilePath(url: dirURL) {
            makeContents(dirURL: dirURL)
            zipContents = nil
        } else {
            makeArchiveContents(archiveURL: dirURL)
        }
    }
    
    func makeContents(dirURL: URL) {
        do {
            var tmpDir: URL = dirURL
            
            if let aliasOriginalDirURL = getAliasOriginalURL(url: tmpDir) {
                tmpDir = aliasOriginalDirURL
                //エイリアスを展開しようとした場合、Originalをキーに参照元を保存しておく
                aliasMapperDic.updateValue(dirURL, forKey: aliasOriginalDirURL)
            }

            let contentUrls = try FileManager.default.contentsOfDirectory(at: tmpDir, includingPropertiesForKeys: nil)
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
                
                var tmpPath: String = content.path
                
                //エイリアスの場合
                if let aliasOriginalURL = getAliasOriginalURL(url: content) {
                    tmpPath = aliasOriginalURL.path
                }
                
                var isDir: ObjCBool = false
                if !FileManager.default.fileExists(atPath: tmpPath, isDirectory: &isDir) {
                    //指定したURLが存在しないってことはこのタイミングではないはず
                    continue
                }
                
                if isDir.boolValue {
                    //dir
                    dirContents!.append(content)
                    continue
                }
                
                if isZipFilePath(url: content) {
                    dirContents!.append(content)
                    continue
                }
                
                //fileContentsにはDirectoryPath/file.jpgの様なpathが入っている
                fileContents!.append(content)
            }
            
            if dirContents!.count == 0 {
                dirContents = nil
            }
            
            if fileContents!.count == 0 {
                fileContents = nil
            }
            
            currentDirURL = dirURL
            
        } catch {
            //Permissionでコケる場合がある。コケてもfileContentsとdirContentsが無いので次の有効なファイルを探しにいくので問題はない
            print(error)
        }
    }
    
    func makeArchiveContents(archiveURL: URL) {
        do {
            let unzip = try ZUnzip(path: archiveURL.path)
            
            let sortFiles = unzip.files.sorted { a, b in
                return a.localizedStandardCompare(b) == ComparisonResult.orderedAscending
            }
            
            fileContents = []
            dirContents = nil
            
            for file in sortFiles {
                print(file)
                
                if file.hasPrefix("__MACOSX") {
                    continue
                }
                
                guard let path = file.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
                    let fileURL = URL(string: path) else {
                    //zipの中のエイリアスは対象外にしておく
                    continue
                }
                
                //ディレクトリは除外。zunzipのfilesは解凍したディレクトリの全てのパスを返すので、ファイルパスだけを保存すればいい
                if fileURL.absoluteString.hasSuffix("/") {
                    continue
                }

                if fileURL.lastPathComponent.hasPrefix(".") {
                    continue
                }
                
                if isZipFilePath(url: fileURL) {
                    makeArchiveContents(archiveURL: fileURL)
                }
                                
                if fileURL.isImageTypeURL() {
                    fileContents!.append(fileURL)
                }
            }
            
            if fileContents!.count == 0 {
                zipContents = nil
                return
            }
            currentDirURL = archiveURL
            zipContents = unzip

        } catch {
            print(error)
        }
    }
    
    func getAliasOriginalURL(url: URL) -> URL? {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.isAliasFileKey])
            
            guard let isAliasFile = resourceValues.isAliasFile else {
                return nil
            }
            
            if !isAliasFile {
                return nil
            }
            
            return try URL(resolvingAliasFileAt: url)
        } catch  {
            print(error)
        }
        return nil
    }

    func isZipFilePath(url: URL) -> Bool {
        
        if url.lastPathComponent.hasSuffix(".zip") {
            return true
        }
        
        return false
    }
}

extension PakapoImageModel {
    // MARK: - search
    /// 有効な画像があれば返す
    /// - Parameter fileURL: ファイルのURL
    func getValidImage(fileURL: URL?) -> NSImage? {
        guard let unwrappedFileURL = fileURL else {
            return nil
        }
        
        if !unwrappedFileURL.isImageTypeURL() {
            return nil
        }
        
        if let unwrappedZipContents = zipContents {
            
            if let imageData = unwrappedZipContents.data(forFile: unwrappedFileURL.path) {
                return NSImage(data: imageData as Data)
            }
        }
        
        var tmpFileURL = unwrappedFileURL
        if let aliasOriginalURL = getAliasOriginalURL(url: unwrappedFileURL) {
            tmpFileURL = aliasOriginalURL
        }
        
        return NSImage(contentsOf: tmpFileURL)
    }

    /// fileContents内の有効な画像を返す
    /// - Parameter fileContents: fileContents。reverseされているfileContentsが来る場合もある
    func getValidImageInFileContents(fileContents: [URL]?) -> NSImage? {
        guard let unwrappedContents = fileContents else {
            return nil
        }
        
        for (index, contentURL) in unwrappedContents.enumerated() {
            fileContentsIndex = index
            guard let unwrappedImage = getValidImage(fileURL: contentURL) else {
                continue
            }
            
            return unwrappedImage
        }

        return nil
    }
    
    /// 起点となる画像を返す。「起動時」「openPanel選択時」「D&D時」に呼ばれ、起点からの開始とする
    /// - Parameter contentURL: ファイル/ディレクトリのURL
    func getStartingPointImage(contentURL: URL) -> NSImage? {
        var isDir: ObjCBool = false
        if !FileManager.default.fileExists(atPath: contentURL.path, isDirectory: &isDir) {
            return nil
        }

        if isDir.boolValue {
            //dir内でContentsを作成
            refreshContents(dirURL: contentURL)
            
            if let unwrappedImage = getValidImageInFileContents(fileContents: fileContents) {
                addOpenRecentDirectories()
                return unwrappedImage
            }
            
            guard let unwrappedDirContents = dirContents else {
                return nil
            }
            
            //zipしかないディレクトリを開かれた可能性があるので検索する
            for dir in unwrappedDirContents {
                if isZipFilePath(url: dir) {
                    refreshContents(dirURL: dir)
                    
                    if let unwrappedImage = getValidImageInFileContents(fileContents: fileContents) {
                        addOpenRecentDirectories()
                        return unwrappedImage
                    }
                    
                    return nil
                }
            }

            return nil
        }
        
        var tmpContentURL: URL = contentURL
        
        if !isZipFilePath(url: contentURL) {
            tmpContentURL = contentURL.deletingLastPathComponent()
        }
        
        //fileが入っているdir内のContentsを作成。zipの場合もある
        refreshContents(dirURL: tmpContentURL)
        
        guard let unwrappedFileContents = fileContents else {
            return nil
        }
        
        var pageURL: URL = contentURL

        /*
         zipの場合、contentURLはzipへのPathを持っている。更にその中のPathについては
         起動時のみUserDefault経由でlastZipPageURLが持っている
         起動後のzip投入については強制的にfileContentsの頭で良い
        */
        if isZipFilePath(url: contentURL) {
            if let unwrappedLastZipPageURL = lastZipPageURL {
                pageURL = unwrappedLastZipPageURL
                lastZipPageURL = nil
            } else {
                pageURL = unwrappedFileContents[0]
            }
        }

        //indexの更新
        fileContentsIndex = unwrappedFileContents.firstIndex(of: pageURL)
        
        //本来ありえないはずだが、前回終了時に保存したURLと、refreshContentsで取得した同じfilepathが違う場合がある
        //どうも日本語がencodeされている部分が違うっぽいが原因不明
        //これが起こった場合、fileContentsIndexとcurrentDirが有効な値になっていないので、file名で見てリカバリする
        if fileContentsIndex == nil {
            for (index, file) in unwrappedFileContents.enumerated() {
                if contentURL.lastPathComponent == file.lastPathComponent {
                    fileContentsIndex = index
                    currentDirURL = file.deletingLastPathComponent()
                    break
                }
            }
            //ファイル名でのリカバリにも失敗。読み直してもらうしかなさそう
            if fileContentsIndex == nil {
                return nil
            }
        }
        
        guard let unwrappedImage = getValidImage(fileURL: pageURL) else {
            return nil
        }
        
        addOpenRecentDirectories()
        
        return unwrappedImage
    }
    
    func getNextImage() -> NSImage? {
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
            if let validDirURL = getCurrentNextChildDirectory(dirURL: unwrappedCurrentDirURL) {
                //currentに次の有効directoryあり
                refreshContents(dirURL: validDirURL)
            } else if let validDirURL = getParentNextDirectory(dirURL: unwrappedCurrentDirURL){
                //親へ遡り、次の有効directoryを発見した
                refreshContents(dirURL: validDirURL)
            } else {
                //次の有効directoryが無い。rootで更新する。
                refreshContents(dirURL: unwrappedRootDirURL)
                
                //rootに有効なfileがない場合は子供の検索
                if fileContents == nil {
                    lastSearchedDirURL = nil
                    
                    guard let validURL = getCurrentNextChildDirectory(dirURL: unwrappedRootDirURL) else {
                        //rootから子供にいたるまで表示可能なcontentがない。openしてもらうしかない
                        return nil
                    }
                    
                    refreshContents(dirURL: validURL)
                }
            }

            lastSearchedDirURL = nil
            unwrappedFileContentsIndex = 0
            
        } else {
            //まだ終点じゃない
            unwrappedFileContentsIndex += 1
        }
        
        fileContentsIndex = unwrappedFileContentsIndex
        
        guard let fileURL = getViewPageURL() else {
            return nil
        }
        
        guard let image = getValidImage(fileURL: fileURL) else {
            return nil
        }
        
        addOpenRecentDirectories()
        
        return image
    }
    
    func getPrevImage() -> NSImage? {
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
            if let validDirURL = getParentPrevDirectory(dirURL: unwrappedCurrentDirURL){
                //親へ遡り、次の有効directoryを発見した
                refreshContents(dirURL: validDirURL)
            } else {
                //次の有効directoryが無い。rootで更新する。
                refreshContents(dirURL: unwrappedRootDirURL)
                
                //rootにdirectoryがある場合は子供の検索
                if dirContents != nil {
                    lastSearchedDirURL = nil
                    
                    guard let validURL = getCurrentChildPrevDirectory(dirURL: unwrappedRootDirURL) else {
                        //rootから子供にいたるまで表示可能なcontentがない。openしてもらうしかない
                        return nil
                    }
                    refreshContents(dirURL: validURL)
                }
            }
            
            lastSearchedDirURL = nil
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
        
        guard let fileURL = getViewPageURL() else {
            return nil
        }
        
        guard let image = getValidImage(fileURL: fileURL) else {
            return nil
        }
        
        addOpenRecentDirectories()
        
        return image
    }
    
    /// 次の検索すべきディレクトリの配列を返す
    func getNextSearchTargetDirectories() -> [URL]? {
        guard var unwrappedDirContents = dirContents else {
            return nil
        }
        
        //以前directoryを調べた事があるならその時点まで持っていく
        
        guard let unwrappedLastDisplayChildDirURL = lastSearchedDirURL,
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
    
    /// 前の検索すべきディレクトリの配列を返す
    func getPrevSearchTargetDirectories() -> [URL]? {
        guard var unwrappedDirContents = dirContents else {
            return nil
        }
        
        //以前directoryを調べた事があるならその位置まで持っていく
        
        guard let unwrappedLastDisplayChildDirURL = lastSearchedDirURL,
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
    
    /// サブフォルダを検索対象とするかどうか
    func canSearchChildDirectory() -> Bool {
        guard let unwrappedRootDirURL = rootDirURL,
              let unwrappedCurrentDirURL = currentDirURL else {
            return false
        }
        
        //rootの子は有効
        if unwrappedRootDirURL.absoluteString == unwrappedCurrentDirURL.absoluteString {
            return true
        }
        
        return UserDefaults.standard.bool(forKey: AppDelegate.SEARCH_CHILD_ENABLE)
    }
    
    /// Currentに含まれているディレクトリで次に有効なファイルを持つディレクトリのURLを返す。子から孫へと有効なファイルが見つかるまで探す
    func getCurrentNextChildDirectory(dirURL: URL) -> URL? {
        if !canSearchChildDirectory() {
            return nil
        }
        
        guard let searchDirectories = getNextSearchTargetDirectories() else {
            return nil
        }
        
        for dir in searchDirectories {
            refreshContents(dirURL: dir)

            if getValidImageInFileContents(fileContents: fileContents) != nil {
                return dir
            }
            
            lastSearchedDirURL = dir
            guard let validURL = getCurrentNextChildDirectory(dirURL: dir) else {
                continue
            }

            return validURL
        }

        return nil
    }
    
    /// Currentに含まれているディレクトリで前に有効なファイルを持つディレクトリのURLを返す。子から孫へと有効なファイルが見つかるまで探す
    func getCurrentChildPrevDirectory(dirURL: URL) -> URL? {
        if !canSearchChildDirectory() {
            return nil
        }

        guard let searchDirectories = getPrevSearchTargetDirectories() else {
            return nil
        }
        
        for dir in searchDirectories {
            
            refreshContents(dirURL: dir)

            if dirContents != nil {
                lastSearchedDirURL = dir
                if let validURL = getCurrentChildPrevDirectory(dirURL: dir) {
                    return validURL
                }
            }
            
            guard let unwrappedFileContents = fileContents else {
                continue
            }
            
            if getValidImageInFileContents(fileContents: unwrappedFileContents.reversed()) != nil {
                return dir
            }
            
        }

        return nil
    }
    
    ///  Currentの親に含まれているディレクトリで次に有効なファイルを持つディレクトリのURLを返す。親から更に親へと有効なファイルが見つかるまで探す
    func getParentNextDirectory(dirURL: URL) -> URL? {
        var tmpDirURL = dirURL
        
        //エイリアスの可能性を考慮する
        if let unwrappedAliasURL = aliasMapperDic[dirURL] {
            tmpDirURL = unwrappedAliasURL
            aliasMapperDic.removeValue(forKey: dirURL)
        }
        
        guard let unwrappedRootDirURL = rootDirURL else {
            return nil
        }
        
        //rootより親は検索対象にしない
        if unwrappedRootDirURL.absoluteString == tmpDirURL.absoluteString {
            return nil
        }
        
        //現状表示しているURLを最後に表示させたURLとして確保しておく
        lastSearchedDirURL = tmpDirURL
        
        let nextDirURL = tmpDirURL.deletingLastPathComponent()

        //親でcontentを更新する
        refreshContents(dirURL: nextDirURL)
        
        guard let searchDirectories = getNextSearchTargetDirectories() else {
            //親に検索対象に出来るdirectoryが存在しなかった。更に親へ
            return getParentNextDirectory(dirURL: nextDirURL)
        }
        
        for dir in searchDirectories {
            guard let validURL = getCurrentNextChildDirectory(dirURL: dir) else {
                continue
            }
            
            return validURL
        }

        return nil
    }
    
    func getParentPrevDirectory(dirURL: URL) -> URL? {
        var tmpDirURL = dirURL
        
        //エイリアスの可能性を考慮する
        if let unwrappedAliasURL = aliasMapperDic[dirURL] {
            tmpDirURL = unwrappedAliasURL
            aliasMapperDic.removeValue(forKey: dirURL)
        }
        
        guard let unwrappedRootDirURL = rootDirURL else {
            return nil
        }
        
        //rootより親は検索対象にしない
        if unwrappedRootDirURL.absoluteString == tmpDirURL.absoluteString {
            return nil
        }
        
        //現状表示しているURLを最後に表示させたURLとして確保しておく
        lastSearchedDirURL = tmpDirURL
        
        let nextDirURL = tmpDirURL.deletingLastPathComponent()

        //親でcontentを更新する
        refreshContents(dirURL: nextDirURL)
        
        guard let searchDirectories = getPrevSearchTargetDirectories() else {
            
            if let unwrappedFileContents = fileContents {
                return unwrappedFileContents.last?.deletingLastPathComponent()
            }
            
            //親に検索対象に出来るdirectoryが存在しなかった。更に親へ
            return getParentPrevDirectory(dirURL: nextDirURL)
        }
        
        for dir in searchDirectories {
            guard let validURL = getCurrentChildPrevDirectory(dirURL: dir) else {
                continue
            }
            
            return validURL
        }

        return nil
    }
}
extension PakapoImageModel {
    // MARK: - shortcut
    /// 次のディレクトリの画像を返す。キーボードショートカット用
    func getNextDirectoryImage() -> NSImage? {
        guard let unwrappedFileContents = fileContents else {
            return nil
        }
        
        //現在のdirectoryの最後まで表示した事にして、後はloadNextImageURLに任せる
        fileContentsIndex = unwrappedFileContents.count - 1
        
        return getNextImage()
    }
    
    /// 前のディレクトリの画像を返す。キーボードショートカット用
    func getPrevDirectoryImage() -> NSImage? {
        //現在のdirectoryの頭まで表示した事にして、一旦loadPrevImageを実行する
        fileContentsIndex = 0
        
        if getPrevImage() == nil {
            return nil
        }
        
        //getPrevImageは前のdirectoryの最後のindexを指す様にfileContentsIndexを変えてしまうので、頭を指す様にしておく
        fileContentsIndex = 0

        //getPrevImageがnilじゃない時点で確実に表示出来るfileがある
        return getValidImage(fileURL: fileContents!.first!)
    }
    
    // MARK: - jump
    func jumpSameDirectory(index: Int) -> NSImage? {
        guard let unwrappedRootDirectories = rootDirectories else {
            return nil
        }
        
        return jumpDirectory(url: unwrappedRootDirectories[index])
    }
    
    func jumpOpenRecentDirectory(index: Int) -> NSImage? {
        guard var openRecentDirectories: [String] = UserDefaults.standard.array(forKey: OPEN_RECENT_DIRECTORIES) as? [String] else {
            return nil
        }
        
        let jumpURL: URL = URL(string: openRecentDirectories[index])!
        
        //ジャンプしたディレクトリを最新にする
        openRecentDirectories.remove(at: index)
        openRecentDirectories.insert(jumpURL.absoluteString, at: 0)
        UserDefaults.standard.set(openRecentDirectories, forKey: OPEN_RECENT_DIRECTORIES)
        
        return jumpDirectory(url: jumpURL)
    }
    
    func jumpDirectory(url: URL) -> NSImage? {
        lastSearchedDirURL = nil
        
        return getStartingPointImage(contentURL: url)
    }
}

extension PakapoImageModel {
    // MARK: - window
    func getViewPageTitle() -> String {
        guard let unwrappedCurrentDirURL = currentDirURL else {
            return ""
        }
        let component = unwrappedCurrentDirURL.pathComponents
        
        return component[component.count - 1]
    }
}

extension PakapoImageModel {
    // MARK: - UserDefault
    func saveRootDirectoryURL(root: URL) -> Bool {
        var isDir: ObjCBool = false
        if !FileManager.default.fileExists(atPath: root.path, isDirectory: &isDir) {
            //指定したURLが存在しないってことはこのタイミングではないはず
            return false
        }
        
        /*
            ## 基本動作：末端のディレクトリを内包するディレクトリをrootとする
            - 引数のURLがファイル/ディレクトリで処理が変わる
                - /tmp/hoge/fuga.jpgの場合はtmpがroot
                - /tmp/hoge/の場合はtmpがroot
            - /Usersの様な場所で選択された場合、削除せず選択された所をrootとする(component.count == 2)
         */

        var saveURL = root
        
        let component = root.pathComponents

        if component.count < 2 {
            // /Volume を選択してもpathComponentsは2なので基本的にないはず
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
    
    func getRootDirectoryURL() -> URL? {
        guard let unwrappedURL = UserDefaults.standard.url(forKey: ROOT_DIRECTORY_URL) else {
            return nil
        }
        
        return unwrappedURL
    }
    
    func getViewPageURL() -> URL? {
        guard let unwrappedFileContentsIndex = fileContentsIndex,
              let unwrappedFileContents = fileContents else {
            return nil
        }
        
        guard unwrappedFileContents.indices.contains(unwrappedFileContentsIndex) else {
            return nil
        }
        
        return unwrappedFileContents[unwrappedFileContentsIndex]
    }
    
    func saveLastViewPageURL() {
        guard let fileURL = getViewPageURL() else {
            return
        }
        
        if zipContents != nil {
           if let unwrappedCurrentDirURL = currentDirURL {
            //zip展開中だった場合、zipのPathを保存しておく
            UserDefaults.standard.set(unwrappedCurrentDirURL, forKey: LAST_ZIP_DIRECTORY_URL)
            }
        }

        UserDefaults.standard.set(fileURL, forKey: LAST_PAGE_URL)
    }
    
    func loadLastViewPageURL() -> URL? {
        guard let unwrappedURL = UserDefaults.standard.url(forKey: LAST_PAGE_URL) else {
            return nil
        }
        
        //前回zip展開中に終了している場合
        if let unwrappedLastZipURL = UserDefaults.standard.url(forKey: LAST_ZIP_DIRECTORY_URL) {
            UserDefaults.standard.removeObject(forKey: LAST_ZIP_DIRECTORY_URL)
            lastZipPageURL = unwrappedURL
            return unwrappedLastZipURL
        }
                
        return unwrappedURL
    }
    
    /// 同じフォルダのフォルダ/アーカイブを作る
    /// - Returns: (チェックマークをつけるindex, rootにあるDirectory配列)
    func makeRootSameDirectories() -> (currentIndex: Int?, directories: [URL]?) {
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
    
    /// 最近開いた本に追加
    func addOpenRecentDirectories() {
        guard let unwrappedCurrentDirURL = currentDirURL else {
            return
        }

        if var openRecentDirectories = getOpenRecentDirectories() {
            if openRecentDirectories.contains(unwrappedCurrentDirURL.absoluteString) {
                return
            }
            
            if openRecentDirectories.count >= OPEN_RECENT_MAX_COUNT {
                openRecentDirectories.removeFirst()
            }
            
            openRecentDirectories.insert(unwrappedCurrentDirURL.absoluteString, at: 0)
            
            UserDefaults.standard.set(openRecentDirectories, forKey: OPEN_RECENT_DIRECTORIES)

        } else {
            let openRecentDirectories: [String] = [unwrappedCurrentDirURL.absoluteString]
            
            UserDefaults.standard.set(openRecentDirectories, forKey: OPEN_RECENT_DIRECTORIES)
        }
    }
    
    /// 最近開いた本を取得する
    /// - Returns: 最近開いた本のパス配列
    func getOpenRecentDirectories() -> [String]? {
        guard let openRecentDirectories: [String] = UserDefaults.standard.array(forKey: OPEN_RECENT_DIRECTORIES) as? [String] else {
            return nil
        }
        
        return openRecentDirectories
    }
}
