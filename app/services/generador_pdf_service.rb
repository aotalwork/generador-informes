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

    # Definimos la zona útil de trabajo dejando un margen holgado
    Prawn::Document.generate(
      ruta,
      page_size: "A4",
      margin: [40, 40, 40, 40]
    ) do |pdf|

      configurar_fuentes(pdf)
      pdf.font_size = 10

      # 1. Dibujar la línea vertical fija y la banda lateral izquierda
      generar_columna_lateral_oficial(pdf)

      # 2. Definir el Pie de Página
      generar_pie(pdf)

      # 3. Restringir todo el texto del informe a la derecha de la línea vertical
      x_inicio_cuerpo = 95
      ancho_cuerpo     = pdf.bounds.width - x_inicio_cuerpo

      pdf.bounding_box([x_inicio_cuerpo, pdf.bounds.top], width: ancho_cuerpo) do
        generar_cabecera_cuerpo(pdf)
        generar_datos_paciente(pdf)
        generar_exploracion_psiquiatrica(pdf)
        generar_dictamen_conclusion(pdf)
      end
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
  # COLUMNA LATERAL (ESCUDO Y LÍNEA VERTICAL CONTINUA)
  # ============================================================

  def generar_columna_lateral_oficial(pdf)
    pdf.repeat(:all) do
      # Línea vertical divisoria continua de arriba a abajo
      pdf.stroke_color "000000"
      pdf.line_width 0.8
      pdf.stroke_line [80, pdf.bounds.top], [80, pdf.bounds.bottom + 20]

      # Dibujar la marca lateral
      pdf.bounding_box([0, pdf.bounds.top], width: 75) do
        ruta_logo = File.expand_path("../../assets/escudospain.png", __dir__)

        if File.exist?(ruta_logo)
          pdf.image ruta_logo, width: 45, position: :center
          pdf.move_down 4
        end

        pdf.text "ADMINISTRACIÓN", size: 6.5, style: :bold, align: :center
        pdf.text "DE JUSTICIA", size: 6.5, style: :bold, align: :center
      end
    end
  end

  # ============================================================
  # CABECERA DEL CUERPO (JUZGADO Y TÍTULO)
  # ============================================================

  def generar_cabecera_cuerpo(pdf)
    juzgado      = obtener_valor_campo("juzgado") || obtener_valor_campo("juzgado_instruccion") || "JUZGADO DE INSTRUCCIÓN"
    procedimiento = obtener_valor_campo("procedimiento") || obtener_valor_campo("expediente") || "—"
    fecha        = obtener_valor_campo("a_fecha_de") || Time.now.strftime("%d/%m/%Y")

    pdf.move_down 5
    pdf.text juzgado.upcase, size: 10.5, style: :bold
    pdf.move_down 2
    pdf.text procedimiento, size: 9.5
    pdf.move_down 18

    pdf.text "INFORME DE SANIDAD MÉDICO FORENSE", size: 11.5, style: :bold, align: :center
    pdf.move_down 15

    pdf.text "<b>Médico Forense:</b> #{MEDICO}", size: 10, inline_format: true
    pdf.text "<b>Fecha:</b> #{fecha}", size: 10, inline_format: true

    if @tipo.respond_to?(:descripcion) && !@tipo.descripcion.to_s.strip.empty?
      pdf.move_down 6
      pdf.text "<i>#{@tipo.descripcion}</i>", size: 9.5, color: "333333", inline_format: true
    end

    pdf.move_down 14
  end

  # ============================================================
  # SECCIÓN I: DATOS DEL PACIENTE
  # ============================================================

  def generar_datos_paciente(pdf)
    filas = []

    campos_paciente = %w[
      nombre_y_apellidos_del_afectado
      dni_nie
      centro_residencial___geriatrico
      antecedentes_medicos_y_tratamientos_relevantes
      juicio_diagnostico_clinico
    ]

    campos_paciente.each do |id|
      campo = buscar_campo(id)
      next unless campo

      valor = @datos[campo.id]
      next if valor.nil? || valor.to_s.strip.empty?

      filas << ["<b>#{campo.nombre}:</b>", formatear_valor(valor)]
    end

    return if filas.empty?

    pdf.text "I. DATOS DEL AFECTADO Y ANTECEDENTES", size: 10, style: :bold
    pdf.move_down 4

    pdf.table(filas, width: pdf.bounds.width) do |t|
      t.cells.padding = [2, 2, 2, 0]
      t.cells.borders = []
      t.cells.size = 9.5
      t.cells.inline_format = true
      t.column(0).width = pdf.bounds.width * 0.45
      t.column(1).width = pdf.bounds.width * 0.55
    end

    pdf.move_down 12
  end

  # ============================================================
  # SECCIÓN II: EXPLORACIÓN PSIQUIÁTRICA
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

      respuestas << "• <b>Pregunta #{numero}:</b> #{frase}"
    end

    return if respuestas.empty?

    pdf.text "II. EXPLORACIÓN PSIQUIÁTRICA", size: 10, style: :bold
    pdf.move_down 6

    respuestas.each do |linea|
      pdf.text linea, size: 9.5, align: :justify, leading: 2, inline_format: true
      pdf.move_down 3
    end

    pdf.move_down 12
  end

  # ============================================================
  # SECCIÓN III: DICTAMEN PERICIAL
  # ============================================================

  def generar_dictamen_conclusion(pdf)
    pdf.text "III. DICTAMEN PERICIAL Y CONCLUSIONES", size: 10, style: :bold
    pdf.move_down 6

    capacidad = obtener_valor_campo("mantiene_capacidad_para_prestar_consentimiento_valido_") || "No"
    riesgo    = obtener_valor_campo("criterios_de_riesgo_detectados") || "Riesgo de autoagresión o desamparo grave"
    dictamen  = obtener_valor_campo("sentido_del_dictamen_pericial") || "Favorable a la ratificación"
    colegiado = obtener_valor_campo("identificacion_del_medico_forense__n__colegiado_") || "—"

    texto_conclusion = <<~TEXTO
      En virtud de la exploración realizada y los antecedentes obrantes:

      1. ¿Mantiene capacidad para prestar consentimiento válido?: <b>#{capacidad}</b>.
      2. Criterios de riesgo detectados: <b>#{riesgo}</b>.
      3. Sentido del dictamen pericial: <b>#{dictamen}</b>.

      Lo que se emite e informa a los efectos judiciales oportunos.
    TEXTO

    pdf.text texto_conclusion, size: 9.5, align: :justify, leading: 2.5, inline_format: true
    pdf.move_down 20

    # Bloque de Firma
    pdf.bounding_box([pdf.bounds.width - 200, pdf.cursor], width: 200) do
      pdf.text "El Médico Forense,", size: 9.5
      pdf.move_down 25
      pdf.text "Fdo.: #{MEDICO}", size: 9.5, style: :bold
      pdf.text "Nº Colegiado / Reg.: #{colegiado}", size: 8.5
    end
  end

  # ============================================================
  # FUNCIONES DE APOYO
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
    pdf.number_pages(
      "Página <page> de <total>",
      at: [pdf.bounds.right - 80, 10],
      size: 8,
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