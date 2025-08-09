import AppKit

final class GeneralTabViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    private struct Mapping {
        var language: String
        var layoutID: String
    }

    private let settingsStore = SettingsStore.shared
    private var sources: [KeyboardInputSource] = []
    private var activeLayouts: Set<String> = []
    private var mappings: [Mapping] = []

    private let layoutsStack = NSStackView()
    private let mappingTable = NSTableView()

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        sources = InputSourcesService.shared.list()
        activeLayouts = Set(settingsStore.settings.layouts.active)
        mappings = settingsStore.settings.layouts.languageMap.map { Mapping(language: $0.key, layoutID: $0.value) }
        setupUI()
    }

    private func setupUI() {
        layoutsStack.orientation = .vertical
        layoutsStack.alignment = .leading
        layoutsStack.spacing = 4
        for src in sources {
            let btn = NSButton(checkboxWithTitle: src.name, target: self, action: #selector(layoutToggled(_:)))
            btn.identifier = NSUserInterfaceItemIdentifier(src.id)
            btn.state = activeLayouts.contains(src.id) ? .on : .off
            layoutsStack.addArrangedSubview(btn)
        }
        let layoutsScroll = NSScrollView()
        layoutsScroll.documentView = layoutsStack
        layoutsScroll.hasVerticalScroller = true
        layoutsScroll.translatesAutoresizingMaskIntoConstraints = false

        // Mapping table
        let langColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("language"))
        langColumn.title = "Language"
        let layoutColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("layout"))
        layoutColumn.title = "Layout"
        mappingTable.addTableColumn(langColumn)
        mappingTable.addTableColumn(layoutColumn)
        mappingTable.delegate = self
        mappingTable.dataSource = self
        let mappingScroll = NSScrollView()
        mappingScroll.documentView = mappingTable
        mappingScroll.hasVerticalScroller = true
        mappingScroll.translatesAutoresizingMaskIntoConstraints = false

        let addButton = NSButton(title: "+", target: self, action: #selector(addMapping))
        let removeButton = NSButton(title: "-", target: self, action: #selector(removeMapping))
        let buttonsStack = NSStackView(views: [addButton, removeButton])
        buttonsStack.orientation = .horizontal
        buttonsStack.spacing = 4
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false

        let mainStack = NSStackView()
        mainStack.orientation = .vertical
        mainStack.spacing = 8
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(NSTextField(labelWithString: "Active layouts"))
        mainStack.addArrangedSubview(layoutsScroll)
        mainStack.addArrangedSubview(NSTextField(labelWithString: "Language → Layout"))
        mainStack.addArrangedSubview(mappingScroll)
        mainStack.addArrangedSubview(buttonsStack)

        view.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            layoutsScroll.heightAnchor.constraint(equalToConstant: 120),
            mappingScroll.heightAnchor.constraint(equalToConstant: 150)
        ])
    }

    @objc private func layoutToggled(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue else { return }
        if sender.state == .on {
            activeLayouts.insert(id)
        } else {
            activeLayouts.remove(id)
        }
        settingsStore.update { $0.layouts.active = Array(activeLayouts) }
    }

    @objc private func addMapping() {
        mappings.append(Mapping(language: "", layoutID: sources.first?.id ?? ""))
        mappingTable.reloadData()
        saveMappings()
    }

    @objc private func removeMapping() {
        let row = mappingTable.selectedRow
        guard row >= 0 && row < mappings.count else { return }
        mappings.remove(at: row)
        mappingTable.reloadData()
        saveMappings()
    }

    private func saveMappings() {
        let dict = Dictionary(uniqueKeysWithValues: mappings.map { ($0.language, $0.layoutID) })
        settingsStore.update { $0.layouts.languageMap = dict }
    }

    // MARK: NSTableView
    func numberOfRows(in tableView: NSTableView) -> Int { mappings.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let mapping = mappings[row]
        if tableColumn?.identifier.rawValue == "language" {
            let tf = NSTextField(string: mapping.language)
            tf.isBordered = false
            tf.backgroundColor = .clear
            tf.action = #selector(languageChanged(_:))
            tf.target = self
            tf.tag = row
            return tf
        } else {
            let popup = NSPopUpButton()
            popup.addItems(withTitles: sources.map { $0.name })
            if let idx = sources.firstIndex(where: { $0.id == mapping.layoutID }) {
                popup.selectItem(at: idx)
            }
            popup.tag = row
            popup.target = self
            popup.action = #selector(layoutChanged(_:))
            return popup
        }
    }

    @objc private func languageChanged(_ sender: NSTextField) {
        let row = sender.tag
        guard row >= 0 && row < mappings.count else { return }
        mappings[row].language = sender.stringValue
        saveMappings()
    }

    @objc private func layoutChanged(_ sender: NSPopUpButton) {
        let row = sender.tag
        guard row >= 0 && row < mappings.count else { return }
        let idx = sender.indexOfSelectedItem
        guard idx >= 0 && idx < sources.count else { return }
        mappings[row].layoutID = sources[idx].id
        saveMappings()
    }
}
