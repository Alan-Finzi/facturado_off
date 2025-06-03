import 'dart:convert';
// To parse this JSON data, do
//
//     final productosMaestro = productosMaestroFromJson(jsonString);

// To parse this JSON data, do
//
//     final productoResponse = productoResponseFromJson(jsonString);

import 'dart:convert';

ProductoResponse productoResponseFromJson(String str) => ProductoResponse.fromJson(json.decode(str));

String productoResponseToJson(ProductoResponse data) => json.encode(data.toJson());

class ProductoResponse {
    int? currentPage;
    List<Datum>? data;
    String? firstPageUrl;
    int? from;
    int? lastPage;
    String? lastPageUrl;
    List<Link>? links;
    String? nextPageUrl;
    String? path;
    int? perPage;
    dynamic prevPageUrl;
    int? to;
    int? total;

    ProductoResponse({
        this.currentPage,
        this.data,
        this.firstPageUrl,
        this.from,
        this.lastPage,
        this.lastPageUrl,
        this.links,
        this.nextPageUrl,
        this.path,
        this.perPage,
        this.prevPageUrl,
        this.to,
        this.total,
    });

    factory ProductoResponse.fromJson(Map<String, dynamic> json) => ProductoResponse(
        currentPage: json["current_page"],
        data: json["data"] == null ? [] : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
        firstPageUrl: json["first_page_url"],
        from: json["from"],
        lastPage: json["last_page"],
        lastPageUrl: json["last_page_url"],
        links: json["links"] == null ? [] : List<Link>.from(json["links"]!.map((x) => Link.fromJson(x))),
        nextPageUrl: json["next_page_url"],
        path: json["path"],
        perPage: json["per_page"],
        prevPageUrl: json["prev_page_url"],
        to: json["to"],
        total: json["total"],
    );

    Map<String, dynamic> toJson() => {
        "current_page": currentPage,
        "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
        "first_page_url": firstPageUrl,
        "from": from,
        "last_page": lastPage,
        "last_page_url": lastPageUrl,
        "links": links == null ? [] : List<dynamic>.from(links!.map((x) => x.toJson())),
        "next_page_url": nextPageUrl,
        "path": path,
        "per_page": perPage,
        "prev_page_url": prevPageUrl,
        "to": to,
        "total": total,
    };
}

class Datum {
    int? id;
    String? nombre;
    String? barcode;
    ProductoTipo? productoTipo;
    int? categoryId;
    String? categoriaName;
    int? marcaId;
    int? proveedorId;
    String? comercioId;
    List<ProductosVariacione>? productosVariaciones;
    List<Stock>? stocks;
    List<ListasPrecio>? listasPrecios;

    Datum({
        this.id,
        this.nombre,
        this.barcode,
        this.productoTipo,
        this.categoryId,
        this.marcaId,
        this.proveedorId,
        this.comercioId,
        this.productosVariaciones,
        this.stocks,
        this.listasPrecios,
        this.categoriaName
    });

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        id: json["id"],
        nombre: json["nombre"],
        barcode: json["barcode"],
        productoTipo: productoTipoValues.map[json["producto_tipo"]]!,
        categoryId: json["category_id"],
        categoriaName: json["categoriaName"],
        marcaId: json["marca_id"],
        proveedorId: json["proveedor_id"],
        comercioId: json["comercio_id"],
        productosVariaciones: json["productos_variaciones"] == null ? [] : List<ProductosVariacione>.from(json["productos_variaciones"]!.map((x) => ProductosVariacione.fromJson(x))),
        stocks: json["stocks"] == null ? [] : List<Stock>.from(json["stocks"]!.map((x) => Stock.fromJson(x))),
        listasPrecios: json["listas_precios"] == null ? [] : List<ListasPrecio>.from(json["listas_precios"]!.map((x) => ListasPrecio.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "nombre": nombre,
        "barcode": barcode,
        "producto_tipo": productoTipoValues.reverse[productoTipo],
        "category_id": categoryId,
        "marca_id": marcaId,
        "proveedor_id": proveedorId,
        "comercio_id": comercioId,
        "productos_variaciones": productosVariaciones == null ? [] : List<dynamic>.from(productosVariaciones!.map((x) => x.toJson())),
        "stocks": stocks == null ? [] : List<dynamic>.from(stocks!.map((x) => x.toJson())),
        "listas_precios": listasPrecios == null ? [] : List<dynamic>.from(listasPrecios!.map((x) => x.toJson())),
    };
}

class ListasPrecio {
    int? id;
    int? productId;
    String? referenciaVariacion;
    String? precioLista;
    int? listaId;
    Lista? lista;

    ListasPrecio({
        this.id,
        this.productId,
        this.referenciaVariacion,
        this.precioLista,
        this.listaId,
        this.lista,
    });

    factory ListasPrecio.fromJson(Map<String, dynamic> json) => ListasPrecio(
        id: json["id"],
        productId: json["product_id"],
        referenciaVariacion: json["referencia_variacion"],
        precioLista: json["precio_lista"],
        listaId: json["lista_id"],
        lista: json["lista"] == null ? null : Lista.fromJson(json["lista"]),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "product_id": productId,
        "referencia_variacion": referenciaVariacion,
        "precio_lista": precioLista,
        "lista_id": listaId,
        "lista": lista?.toJson(),
    };
}

class Lista {
    int? id;
    String? nombre;

    Lista({
        this.id,
        this.nombre,
    });

    factory Lista.fromJson(Map<String, dynamic> json) => Lista(
        id: json["id"],
        nombre: json["nombre"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "nombre": nombre,
    };
}

enum ProductoTipo {
    S,
    V
}

final productoTipoValues = EnumValues({
    "s": ProductoTipo.S,
    "v": ProductoTipo.V
});

class ProductosVariacione {
    int? productId;
    String? codigoVariacion;
    String? referenciaVariacion;
    String? variaciones;
    String? cost;
    String? precioInterno;
    List<Stock>? stocks;
    List<ListasPrecio>? listasPrecios;

    ProductosVariacione({
        this.productId,
        this.codigoVariacion,
        this.referenciaVariacion,
        this.variaciones,
        this.cost,
        this.precioInterno,
        this.stocks,
        this.listasPrecios,
    });

    factory ProductosVariacione.fromJson(Map<String, dynamic> json) => ProductosVariacione(
        productId: json["product_id"],
        codigoVariacion: json["codigo_variacion"],
        referenciaVariacion: json["referencia_variacion"],
        variaciones: json["variaciones"],
        cost: json["cost"],
        precioInterno: json["precio_interno"],
        stocks: json["stocks"] == null ? [] : List<Stock>.from(json["stocks"]!.map((x) => Stock.fromJson(x))),
        listasPrecios: json["listas_precios"] == null ? [] : List<ListasPrecio>.from(json["listas_precios"]!.map((x) => ListasPrecio.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "product_id": productId,
        "codigo_variacion": codigoVariacion,
        "referencia_variacion": referenciaVariacion,
        "variaciones": variaciones,
        "cost": cost,
        "precio_interno": precioInterno,
        "stocks": stocks == null ? [] : List<dynamic>.from(stocks!.map((x) => x.toJson())),
        "listas_precios": listasPrecios == null ? [] : List<dynamic>.from(listasPrecios!.map((x) => x.toJson())),
    };
}

class Stock {
    int? id;
    int? productId;
    String? referenciaVariacion;
    String? stock;
    int? sucursalId;
    dynamic sucursal;

    Stock({
        this.id,
        this.productId,
        this.referenciaVariacion,
        this.stock,
        this.sucursalId,
        this.sucursal,
    });

    factory Stock.fromJson(Map<String, dynamic> json) => Stock(
        id: json["id"],
        productId: json["product_id"],
        referenciaVariacion: json["referencia_variacion"],
        stock: json["stock"],
        sucursalId: json["sucursal_id"],
        sucursal: json["sucursal"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "product_id": productId,
        "referencia_variacion": referenciaVariacion,
        "stock": stock,
        "sucursal_id": sucursalId,
        "sucursal": sucursal,
    };
}

class Link {
    String? url;
    String? label;
    bool? active;

    Link({
        this.url,
        this.label,
        this.active,
    });

    factory Link.fromJson(Map<String, dynamic> json) => Link(
        url: json["url"],
        label: json["label"],
        active: json["active"],
    );

    Map<String, dynamic> toJson() => {
        "url": url,
        "label": label,
        "active": active,
    };
}

class EnumValues<T> {
    Map<String, T> map;
    late Map<T, String> reverseMap;

    EnumValues(this.map);

    Map<T, String> get reverse {
        reverseMap = map.map((k, v) => MapEntry(v, k));
        return reverseMap;
    }
}
