//
//  TNSeedInputCell.swift
//  TrustNote
//
//  Created by zenghailong on 2018/3/30.
//  Copyright © 2018年 org.trustnote. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxDataSources

class TNSeedSearchCell: UITableViewCell {
    
    public let resultLabel = UILabel().then {
        
        $0.textAlignment = NSTextAlignment.center
        $0.font = UIFont.systemFont(ofSize: 14.0)
    }
    
    public let lineView = UIView().then {
        $0.backgroundColor = UIColor.hexColor(rgbValue: 0xf1f1f1)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(resultLabel)
        resultLabel.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        contentView.addSubview(lineView)
        lineView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(1.0)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TNSeedInputCell: UICollectionViewCell {
    
    public let textField = UITextField().then {
        
        $0.backgroundColor = UIColor.hexColor(rgbValue: 0xededed)
        $0.textAlignment = NSTextAlignment.center
        $0.keyboardType = .asciiCapable
        $0.font = UIFont.systemFont(ofSize: 16.0)
        $0.textColor = UIColor.hexColor(rgbValue: 0x333333)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubView()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TNSeedInputCell {
    
    fileprivate func configureSubView() {
       
        layer.masksToBounds = true
        layer.cornerRadius = 3.0
        contentView.addSubview(textField)
        
        textField.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

    }
}

final class TNSeedContainerView: UIView {
    
    fileprivate struct Metric {
        
        static let Total_Mnemonic_Count: Int = 12
        static let lineSpacing: CGFloat = 8.0
        static let TextField_Tag_Begin: Int = 50
        static let Max_Words_Count: Int = 3
        static let Input_Char_Limited: Int = 8
    }
    
    private let disposeBag = DisposeBag()
    
    fileprivate var itemWidth: CGFloat = 0
    
    fileprivate var itemHeight: CGFloat = 0
    
    fileprivate var selectedIndex: Int = -1
    
    fileprivate var resultWords: [String] = []
    
    fileprivate var textFields: [UITextField] = []
    
    fileprivate var queryWord: String = ""
    
    fileprivate var isDisplay: BehaviorRelay<Bool> =  BehaviorRelay(value: false) // Whether to display a search list
    
    fileprivate lazy var layout: UICollectionViewFlowLayout = {
       
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = Metric.lineSpacing
        layout.minimumInteritemSpacing = Metric.lineSpacing
        layout.sectionInset = UIEdgeInsets.zero
        return layout
    }()
    
    private let searchResultListView = UITableView().then {

        $0.backgroundColor = UIColor.clear
        $0.layer.borderWidth = 1.0
        $0.layer.borderColor = UIColor.hexColor(rgbValue: 0xf1f1f1).cgColor
    }
    
    lazy var keyboardView: TNKeyboardView = {
        
        let keyboard = TNKeyboardView()
        return keyboard
    }()
    
    lazy var allWords: [String] = {
        
        let path = Bundle.main.path(forResource: "BIP39Words", ofType: "plist")
        let words: [String] = NSArray(contentsOfFile: path!) as! [String]
        return words
    }()
    
    private var collectionView: UICollectionView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configureCollectionView()
        addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        searchResultListView.separatorStyle = .none
        searchResultListView.delegate = self
        searchResultListView.dataSource = self
        searchResultListView.separatorStyle = .none
        searchResultListView.register(TNSeedSearchCell.self, forCellReuseIdentifier: NSStringFromClass(TNSeedSearchCell.self))
        
        bindUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        itemWidth = (collectionView.width - 3 * Metric.lineSpacing) / 4
        itemHeight = (collectionView.height - 2 * Metric.lineSpacing) / 3
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        layout.invalidateLayout()
    }
    
    // Let the child view respond to the event beyond the parent scope and respond to clicks outside the scope of UIView.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        var view = super.hitTest(point, with: event)
        if view == nil {
            for subView in self.subviews {
                let tPoint = subView.convert(point, from: self)
                if (subView.bounds.contains(tPoint)) {
                    view = subView
                }
            }
        }
        return view
    }
    
    private func configureCollectionView() {
    
        collectionView = UICollectionView.init(frame: self.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.register(TNSeedInputCell.self, forCellWithReuseIdentifier: "TNSeedInputCellIndentifier")
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    // MARK:- update dispaly status
    private func updateDisplayStatus(isDisplay: Bool) {
        
        if isDisplay {
            addSubview(searchResultListView)
            let row: Int = Int(selectedIndex / 4)
            let column: Int = selectedIndex % 4
            searchResultListView.frame = CGRect(x: CGFloat(column) * (itemWidth + Metric.lineSpacing), y: CGFloat(row + 1) * (itemHeight + Metric.lineSpacing), width: itemWidth, height: itemHeight * CGFloat(resultWords.count))
        } else {
            searchResultListView.removeFromSuperview()
        }
       
    }
    
    private func bindUI() {
        
        // Binding event
        isDisplay.asObservable().subscribe(onNext: { [weak self] beel in
            
            guard let `self` = self else { return }
            self.updateDisplayStatus(isDisplay: beel)
            
        }).disposed(by: disposeBag)
        
        // Notice to monitor the disappearance of the keyboard
        _ = NotificationCenter.default.rx.notification(Notification.Name.UIKeyboardWillHide).takeUntil(self.rx.deallocated).subscribe(onNext: { [unowned self] _ in

            if self.isDisplay.value {
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                    self.isDisplay.accept(false)
                }
            }
        })
        
    }
}

extension TNSeedContainerView: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return Metric.Total_Mnemonic_Count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if textFields.count == Metric.Total_Mnemonic_Count {
            textFields.removeAll()
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TNSeedInputCellIndentifier", for: indexPath) as! TNSeedInputCell
        cell.textField.delegate = self
        cell.textField.inputView = keyboardView
        cell.textField.tag = indexPath.item + Metric.TextField_Tag_Begin
        textFields.append(cell.textField)
        cell.textField
            .rx.text
            .orEmpty
            .debounce(0.1, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            /*.filter {!$0.isEmpty}*/
            .subscribe(onNext: { [unowned self] query in
                // remove all element
                self.resultWords.removeAll()
                guard query.count > 0 else {
                    self.isDisplay.accept(false)
                    return
                }
                self.queryWord = query
                self.searchAction()
            })
            .disposed(by: disposeBag)
        return cell
    }
}

extension TNSeedContainerView: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultWords.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(TNSeedSearchCell.self)) as! TNSeedSearchCell
        let resultWord = resultWords[indexPath.row]
        if resultWord.isEqual(queryWord) {
            cell.resultLabel.text = resultWord
            cell.resultLabel.textColor = UIColor.black
        } else {
            let attrString = NSMutableAttributedString(string: resultWord)
            let queryRange = NSRange(location: 0, length: queryWord.count)
            let normalRange = NSRange(location: queryWord.count, length: resultWord.count - queryWord.count)
            attrString.addAttributes([NSAttributedStringKey.foregroundColor: UIColor.black], range: queryRange)
            attrString.addAttributes([NSAttributedStringKey.foregroundColor: UIColor.hexColor(rgbValue: 0x666666)], range: normalRange)
            cell.resultLabel.attributedText = attrString
        }
        
        if indexPath.row == tableView.numberOfRows(inSection: 0) - 1 && resultWords.count > 1 {
            cell.lineView.isHidden = true
        } else {
            cell.lineView.isHidden = false
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return itemHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath) as! TNSeedSearchCell
        let textField = textFields[selectedIndex]
        textField.text = cell.resultLabel.text
        guard selectedIndex != Metric.Total_Mnemonic_Count - 1 else {return}
        let nextTextField = textFields[selectedIndex + 1]
        nextTextField.becomeFirstResponder()
    }
}

extension TNSeedContainerView: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        if isDisplay.value && selectedIndex != textField.tag - Metric.TextField_Tag_Begin {
             isDisplay.accept(false)
        }
        selectedIndex = textField.tag - Metric.TextField_Tag_Begin
        keyboardView.textInput = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
       
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
       
        if textField.text?.count == Metric.Input_Char_Limited
        {
            return false
        }
        return true
    }
}

/// MARK: Handle events
extension TNSeedContainerView {
    
    fileprivate func setupSearchresultList() {
        
        searchResultListView.reloadData()
         isDisplay.accept(true)
    }
    
    fileprivate func searchAction() {
        
        for word in self.allWords {
            let count = self.resultWords.count
            guard  count < Metric.Max_Words_Count else {break}
            if word.hasPrefix(queryWord) {
                self.resultWords.append(word)
            }
        }
        guard self.resultWords.count > 0 else {
            isDisplay.accept(false)
            return
        }
        self.setupSearchresultList()
    }
}

