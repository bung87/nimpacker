
productName = "NimPacker"

fileAssociations = @[
    DocumentType(
        exts: @["xlsx", "xls"], 
        mimes: @[
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "application/vnd.ms-excel"
        ],
        utis: @[
            "org.openxmlformats.spreadsheetml.sheet",
            "com.microsoft.excel.xls"
            ],
        role: DocumentTypeRole.Viewer
    )
]