// To parse this JSON data, do
//
//     final datosFacturacionModel = datosFacturacionModelFromJson(jsonString);

import 'dart:convert';

List<DatosFacturacionModel> datosFacturacionModelFromJson(String str) => List<DatosFacturacionModel>.from(json.decode(str).map((x) => DatosFacturacionModel.fromJson(x)));

String datosFacturacionModelToJson(List<DatosFacturacionModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class DatosFacturacionModel {
    int? id;
    String? razonSocial;
    int? comercioId;
    int? provincia;
    String? localidad;
    String? domicilioFiscal;
    double? ivaDefecto;
    DateTime? fechaInicioActividades;
    CondicionIva? condicionIva;
    String? iibb;
    String? cuit;
    String? ptoVenta;
    int? relacionPrecioIva;
    int? habilitadoAfip;
    int? eliminado;
    int? predeterminado;
    DateTime? updatedAt;
    DateTime? createdAt;

    DatosFacturacionModel({
        this.id,
        this.razonSocial,
        this.comercioId,
        this.provincia,
        this.localidad,
        this.domicilioFiscal,
        this.ivaDefecto,
        this.fechaInicioActividades,
        this.condicionIva,
        this.iibb,
        this.cuit,
        this.ptoVenta,
        this.relacionPrecioIva,
        this.habilitadoAfip,
        this.eliminado,
        this.predeterminado,
        this.updatedAt,
        this.createdAt,
    });

    factory DatosFacturacionModel.fromJson(Map<String, dynamic> json) => DatosFacturacionModel(
        id: json["id"],
        razonSocial: json["razon_social"],
        comercioId: json["comercio_id"],
        provincia: json["provincia"],
        localidad: json["localidad"],
        domicilioFiscal: json["domicilio_fiscal"],
        ivaDefecto: json["iva_defecto"].toDouble(),
        fechaInicioActividades: DateTime.parse(json["fecha_inicio_actividades"]),
        condicionIva: condicionIvaValues.map[json["condicion_iva"]],
        iibb: json["iibb"],
        cuit: json["cuit"],
        ptoVenta: json["pto_venta"],
        relacionPrecioIva: json["relacion_precio_iva"],
        habilitadoAfip: json["habilitado_afip"],
        eliminado: json["eliminado"],
        predeterminado: json["predeterminado"],
        updatedAt: DateTime.parse(json["updated_at"]),
        createdAt: DateTime.parse(json["created_at"]),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "razon_social": razonSocial,
        "comercio_id": comercioId,
        "provincia": provincia,
        "localidad": localidad,
        "domicilio_fiscal": domicilioFiscal,
        "iva_defecto": ivaDefecto,
        "fecha_inicio_actividades": fechaInicioActividades?.toIso8601String(),
        "condicion_iva": condicionIvaValues.reverse[condicionIva],
        "iibb": iibb,
        "cuit": cuit,
        "pto_venta": ptoVenta,
        "relacion_precio_iva": relacionPrecioIva,
        "habilitado_afip": habilitadoAfip,
        "eliminado": eliminado,
        "predeterminado": predeterminado,
        "updated_at": updatedAt?.toIso8601String(),
        "created_at": createdAt?.toIso8601String(),
    };
}

enum CondicionIva {
    ELEGIR,
    IVA_RESPONSABLE_INSCRIPTO,
    MONOTRIBUTO
}

final condicionIvaValues = EnumValues({
    "Elegir": CondicionIva.ELEGIR,
    "IVA Responsable inscripto": CondicionIva.IVA_RESPONSABLE_INSCRIPTO,
    "Monotributo": CondicionIva.MONOTRIBUTO
});

class EnumValues<T> {
    Map<String, T> map;
    late Map<T, String> reverseMap;

    EnumValues(this.map);

    Map<T, String> get reverse {
        reverseMap = map.map((k, v) => MapEntry(v, k));
        return reverseMap;
    }
}
