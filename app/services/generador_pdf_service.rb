# frozen_string_literal: true

require "prawn"
require "prawn/table"
require "fileutils"

class GeneradorPdfService

  MEDICO = "JUAN POLO LÓPEZ"

  # ============================================================
  # FUENTES
  # ============================================================

  FUENTES_DIR = File.expand_path("../../assets/fonts", __dir__)

  FUENTE_REGULAR     = File.join(FUENTES_DIR, "LiberationSerif-Regular.ttf")
  FUENTE_BOLD        = File.join(FUENTES_DIR, "LiberationSerif-Bold.ttf")
  FUENTE_ITALIC      = File.join(FUENTES_DIR, "LiberationSerif-Italic.ttf")
  FUENTE_BOLD_ITALIC = File.join(FUENTES_DIR, "LiberationSerif-BoldItalic.ttf")

  # ============================================================
  # INICIALIZACIÓN
  # ============================================================

  def initialize(tipo, datos)
    @tipo  = tipo
    @datos = datos
  end

  # ============================================================
  # GENERAR PDF
  # ============================================================

  def generar(ruta)
    FileUtils.mkdir_p(File.dirname(ruta))

    # Márgenes administrativos oficiales (A4: Top 40, Bottom 50, Left 60, Right 50)
    Prawn::Document.generate(
      ruta,
      page_size: "A4",
      margin: [40, 50, 50, 60]
    ) do |pdf|

      configurar_fuentes(pdf)
      pdf.font_size = 10

      # 1. Pie de página formal
      generar_pie(pdf)

      # 2. Encabezado judicial
      generar_cabecera_oficial(pdf)

      # 3. Datos del expediente / procedimiento
      generar_bloque_expediente(pdf)

      # 4. Datos del paciente y antecedentes
      generar_datos_paciente(pdf)

      # 5. Exploración psiquiátrica
      generar_exploracion_psiquiatrica(pdf)

      # 6. Dictamen / Conclusión oficial
      generar_dictamen_conclusion(pdf)
    end

    ruta
  end

  private

  def configurar_fuentes(pdf)
    pdf.font_families.update(
      "LiberationSerif" => {
        normal:      FUENTE_REGULAR,
        bold:        FUENTE_BOLD,
        italic:      FUENTE_ITALIC,
        bold_italic: FUENTE_BOLD_ITALIC
      }
    )
    pdf.font "LiberationSerif"
  end

  # ============================================================
  # ENCABEZADO JUDICIAL OFICIAL
  # ============================================================

  def generar_cabecera_oficial(pdf)
    ruta_logo    = File.expand_path("../../assets/escudospain.png", __dir__)
    ancho_escudo = 42
    posicion_y   = pdf.cursor

    # Escudo Oficial de España / Administración de Justicia
    if File.exist?(ruta_logo)
      pdf.image ruta_logo, at: [0, posicion_y], width: ancho_escudo
    end

    # Texto Institucional centrado
    pdf.bounding_box([ancho_escudo + 15, posicion_y], width: pdf.bounds.width - (ancho_escudo + 15)) do
      pdf.text "ADMINISTRACIÓN DE JUSTICIA", size: 10, style: :bold, align: :center
      pdf.text "INSTITUTO DE MEDICINA LEGAL Y CIENCIAS FORENSES", size: 9, style: :bold, align: :center
      pdf.text "CLÍNICA MÉRICO FORENSE", size: 8.5, align: :center
    end

    pdf.y = posicion_y - ancho_escudo - 10
    pdf.stroke_color "000000"
    pdf.line_width 1
    pdf.stroke_horizontal_rule
    pdf.move_down 12

    # Título oficial del informe
    pdf.text "INFORME MÉDICO-FORENSE", size: 11, style: :bold, align: :center
    pdf.move_down 4

    if @tipo.respond_to?(:descripcion) && !@tipo.descripcion.to_s.strip.empty?
      pdf.text "<u>#{@tipo.descripcion.to_s.upcase}</u>", size: 9.5, style: :bold, align: :center, inline_format: true
    end

    pdf.move_down 14
  end

  # ============================================================
  # BLOQUE DE REFERENCIA JUDICIAL
  # ============================================================

  def generar_bloque_expediente(pdf)
    juzgado      = obtener_valor_campo("juzgado") || obtener_valor_campo("juzgado_instruccion") || "—"
    procedimiento = obtener_valor_campo("procedimiento") || obtener_valor_campo("expediente") || "—"
    fecha        = obtener_valor_campo("a_fecha_de") || Time.now.strftime("%d/%m/%Y")

    datos_ref = [
      ["<b>ÓRGANO JUDICIAL:</b> #{juzgado}", "<b>FECHA:</b> #{fecha}"],
      ["<b>PROCEDIMIENTO/DILIGENCIAS:</b> #{procedimiento}", "<b>MÉDICO FORENSE:</b> #{MEDICO}"]
    ]

    pdf.table(datos_ref, width: pdf.bounds.width) do |t|
      t.cells.padding = [2, 4, 2, 4]
      t.cells.borders = []
      t.cells.size = 9.5
      t.cells.inline_format = true
      t.column(0).width = pdf.bounds.width * 0.60
      t.column(1).width = pdf.bounds.width * 0.40
    end

    pdf.move_down 8
    pdf.stroke_color "CCCCCC"
    pdf.line_width 0.5
    pdf.stroke_horizontal_rule
    pdf.move_down 10
  end

  # ============================================================
  # DATOS DEL AFECTADO Y EVALUACIÓN
  # ============================================================

  def generar_datos_paciente(pdf)
    pdf.text "I. DATOS DEL AFECTADO Y ANTECEDENTES", size: 10, style: :bold
    pdf.move_down 6

    filas_paciente = []

    campos_ordenados = %w[
      nombre_y_apellidos_del_afectado
      dni_nie
      centro_residencial___geriatrico
      antecedentes_medicos_y_tratamientos_relevantes
      juicio_diagnostico_clinico
    ]

    campos_ordenados.each do |id_campo|
      campo = buscar_campo(id_campo)
      next unless campo

      valor = @datos[campo.id]
      next if valor.nil? || valor.to_s.strip.empty?

      filas_paciente << [
        "<b>#{campo.nombre}:</b>",
        formatear_valor(valor)
      ]
    end

    if filas_paciente.any?
      pdf.table(filas_paciente, width: pdf.bounds.width) do |t|
        t.cells.padding = [3, 4, 3, 4]
        t.cells.borders = []
        t.cells.size = 9.5
        t.cells.inline_format = true
        t.column(0).width = pdf.bounds.width * 0.38
        t.column(1).width = pdf.bounds.width * 0.62
      end
    end

    pdf.move_down 10
  end

  # ============================================================
  # EXPLORACIÓN PSIQUIÁTRICA
  # ============================================================

  def generar_exploracion_psiquiatrica(pdf)
    respuestas = []

    (1..10).each do |numero|
      id = "pregunta_#{numero}"
      campo = buscar_campo(id)
      next unless campo

      valor = @datos[campo.id]
      next if valor.nil? || valor.to_s.strip.empty?

      frase = obtener_frase(campo, valor)
      next if frase.to_s.strip.empty?

      respuestas << "<b>- Pregunta #{numero}:</b> #{frase}"
    end

    return if respuestas.empty?

    pdf.text "II. EXPLORACIÓN PSIQUIÁTRICA Y ESTADO ACTUAL", size: 10, style: :bold
    pdf.move_down 6

    respuestas.each do |linea|
      pdf.text linea, size: 9.5, align: :justify, leading: 2.5, inline_format: true
      pdf.move_down 3
    end

    pdf.move_down 10
  end

  # ============================================================
  # DICTAMEN / CONCLUSIÓN OFICIAL
  # ============================================================

  def generar_dictamen_conclusion(pdf)
    pdf.text "III. DICTAMEN PERICIAL Y CONCLUSIONES", size: 10, style: :bold
    pdf.move_down 6

    capacidad = obtener_valor_campo("mantiene_capacidad_para_prestar_consentimiento_valido_") || "No"
    riesgo    = obtener_valor_campo("criterios_de_riesgo_detectados") || "Riesgo de autoagresión o desamparo grave"
    dictamen  = obtener_valor_campo("sentido_del_dictamen_pericial") || "Favorable a la ratificación"
    colegiado = obtener_valor_campo("identificacion_del_medico_forense__n__colegiado_") || "g"

    texto_conclusion = <<~TEXTO
      En virtud de la exploración realizada y los antecedentes obrantes en la causa:

      1. ¿Mantiene capacidad para prestar consentimiento válido?: <b>#{capacidad}</b>.
      2. Criterios de riesgo detectados: <b>#{riesgo}</b>.
      3. Sentido del dictamen pericial: <b>#{dictamen}</b>.

      Lo que se emite e informa a los efectos judiciales oportunos.
    TEXTO

    pdf.text texto_conclusion, size: 9.5, align: :justify, leading: 3, inline_format: true
    pdf.move_down 25

    # Bloque de Firma Oficial
    pdf.bounding_box([pdf.bounds.width - 220, pdf.cursor], width: 220) do
      pdf.text "El Médico Forense,", size: 9.5, align: :center
      pdf.move_down 30
      pdf.text "Fdo.: #{MEDICO}", size: 9.5, style: :bold, align: :center
      pdf.text "Nº Colegiado / Reg.: #{colegiado}", size: 8.5, align: :center
    end
  end

  # ============================================================
  # AYUDANTES Y AUXILIARES
  # ============================================================

  def obtener_valor_campo(id)
    campo = buscar_campo(id)
    return nil unless campo

    valor = @datos[campo.id]
    return nil if valor.nil? || valor.to_s.strip.empty?

    formatear_valor(valor)
  end

  def buscar_campo(id)
    return nil unless @tipo.respond_to?(:campos)
    @tipo.campos.find { |c| c.id.to_s.downcase == id.to_s.downcase }
  end

  def obtener_frase(campo, valor)
    return "" if valor.nil?
    return formatear_valor(valor) unless campo.respond_to?(:frases) && campo.frases

    frases = campo.frases || {}
    clave  = valor.to_s

    frase = frases[clave] || frases[valor] || frases[clave.to_i]
    return formatear_valor(valor) if frase.nil?

    frase.to_s
  end

  def generar_pie(pdf)
    pdf.repeat(:all) do
      pdf.canvas do
        posicion_y = 22
        margin_x   = 60

        pdf.draw_text(
          "INFORME MÉDICO-FORENSE — ADMINISTRACIÓN DE JUSTICIA",
          at: [margin_x, posicion_y],
          size: 7.5,
          color: "444444"
        )
      end
    end

    pdf.number_pages(
      "Página <page> de <total>",
      at: [pdf.bounds.right - 80, 22 - pdf.bounds.absolute_bottom],
      size: 7.5,
      align: :right,
      color: "444444"
    )
  end

  def formatear_valor(valor)
    return "" if valor.nil?

    case valor
    when TrueClass
      "Sí"
    when FalseClass
      "No"
    when Array
      valor.join(", ")
    else
      valor.to_s
    end
  end

end