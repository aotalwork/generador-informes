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

  def initialize(tipo, datos)
    @tipo  = tipo
    @datos = datos || {}
  end

  def generar(ruta)
    FileUtils.mkdir_p(File.dirname(ruta))

    Prawn::Document.generate(
      ruta,
      page_size: "A4",
      margin: [35, 40, 35, 40]
    ) do |pdf|

      configurar_fuentes(pdf)
      pdf.font_size = 9.5

      # 1. Columna lateral con escudo y línea
      generar_columna_lateral_oficial(pdf)

      # 2. Pie de página
      generar_pie(pdf)

      # 3. Delimitar el área útil de trabajo a la derecha
      x_inicio_cuerpo = 90
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

  def generar_columna_lateral_oficial(pdf)
    pdf.repeat(:all) do
      # Línea vertical divisoria continua
      pdf.stroke_color "000000"
      pdf.line_width 0.8
      pdf.stroke_line [75, pdf.bounds.top], [75, pdf.bounds.bottom + 15]

      pdf.bounding_box([0, pdf.bounds.top], width: 70) do
        ruta_logo = File.expand_path("../../assets/escudospain.png", __dir__)

        if File.exist?(ruta_logo)
          pdf.image ruta_logo, width: 42, position: :center
          pdf.move_down 4
        end

        pdf.text "ADMINISTRACIÓN", size: 6.5, style: :bold, align: :center
        pdf.text "DE JUSTICIA", size: 6.5, style: :bold, align: :center
      end
    end
  end

  def generar_cabecera_cuerpo(pdf)
    juzgado       = obtener_valor_flexible(%w[juzgado juzgado_instruccion organo_judicial]) || "JUZGADO DE INSTRUCCIÓN"
    procedimiento = obtener_valor_flexible(%w[procedimiento expediente diligencias jf]) || "—"
    fecha         = obtener_valor_flexible(%w[a_fecha_de fecha fecha_dictamen]) || Time.now.strftime("%d/%m/%Y")

    pdf.move_down 2
    pdf.text juzgado.upcase, size: 10, style: :bold
    pdf.text "PROCEDIMIENTO / DILIGENCIAS: #{procedimiento}", size: 9
    pdf.move_down 10

    pdf.text "INFORME MÉDICO-FORENSE DE RATIFICACIÓN DE INTERNAMIENTO INVOLUNTARIO", size: 10.5, style: :bold, align: :center
    pdf.text "(Art. 763 Ley de Enjuiciamiento Civil)", size: 8.5, style: :italic, align: :center
    pdf.move_down 10

    pdf.text "<b>Médico Forense:</b> #{MEDICO}", size: 9.5, inline_format: true
    pdf.text "<b>Fecha de Dictamen:</b> #{fecha}", size: 9.5, inline_format: true
    pdf.move_down 10
  end

  # ============================================================
  # I. DATOS DEL AFECTADO Y ANTECEDENTES (Búsqueda tolerante)
  # ============================================================

  def generar_datos_paciente(pdf)
    filas = []

    mapa_campos = [
      ["Nombre y Apellidos:", %w[nombre_y_apellidos_del_afectado nombre afectado paciente]],
      ["DNI/NIE:", %w[dni_nie dni nie]],
      ["Centro Residencial:", %w[centro_residencial___geriatrico centro geriatrico residencia]],
      ["Antecedentes y Tratamientos:", %w[antecedentes_medicos_y_tratamientos_relevantes antecedentes tratamiento]],
      ["Juicio Diagnóstico:", %w[juicio_diagnostico_clinico diagnostico juicio_diagnostico]]
    ]

    mapa_campos.each do |etiqueta, claves|
      valor = obtener_valor_flexible(claves)
      next if valor.nil? || valor.to_s.strip.empty?

      filas << ["<b>#{etiqueta}</b>", valor]
    end

    # Se muestra la sección solo si existen datos a imprimir
    return if filas.empty?

    pdf.text "I. DATOS DE IDENTIFICACIÓN Y CLÍNICOS", size: 9.5, style: :bold
    pdf.move_down 4

    pdf.table(filas, width: pdf.bounds.width) do |t|
      t.cells.padding = [2, 2, 2, 0]
      t.cells.borders = []
      t.cells.size = 9
      t.cells.inline_format = true
      t.column(0).width = pdf.bounds.width * 0.40
      t.column(1).width = pdf.bounds.width * 0.60
    end

    pdf.move_down 10
  end

  # ============================================================
  # II. EXPLORACIÓN PSIQUIÁTRICA (Viñetas garantizadas)
  # ============================================================

  def generar_exploracion_psiquiatrica(pdf)
    respuestas = []

    (1..10).each do |numero|
      clave = "pregunta_#{numero}"
      campo = buscar_campo(clave)
      next unless campo

      valor = @datos[campo.id]
      next if valor.nil? || valor.to_s.strip.empty?

      frase = obtener_frase(campo, valor)
      next if frase.to_s.strip.empty?

      respuestas << "• <b>Pregunta #{numero}:</b> #{frase}"
    end

    return if respuestas.empty?

    pdf.text "II. EXPLORACIÓN PSIQUIÁTRICA", size: 9.5, style: :bold
    pdf.move_down 4

    respuestas.each do |linea|
      pdf.text linea, size: 9, align: :justify, leading: 1.5, inline_format: true
      pdf.move_down 2
    end

    pdf.move_down 10
  end

  # ============================================================
  # III. EVALUACIÓN Y DICTAMEN PERICIAL
  # ============================================================

  def generar_dictamen_conclusion(pdf)
    pdf.text "III. EVALUACIÓN Y DICTAMEN PERICIAL", size: 9.5, style: :bold
    pdf.move_down 4

    capacidad = obtener_valor_flexible(%w[mantiene_capacidad_para_prestar_consentimiento_valido_ capacidad consentimiento]) || "No"
    riesgo    = obtener_valor_flexible(%w[criterios_de_riesgo_detectados riesgo criterios_riesgo]) || "Riesgo de autoagresión o desamparo grave"
    dictamen  = obtener_valor_flexible(%w[sentido_del_dictamen_pericial dictamen sentido_dictamen]) || "Favorable a la ratificación"
    colegiado = obtener_valor_flexible(%w[identificacion_del_medico_forense__n__colegiado_ colegiado reg]) || "—"

    pdf.text "• <b>Capacidad de Consentimiento:</b> #{capacidad} mantiene capacidad para prestar consentimiento libre y válido.", size: 9, inline_format: true
    pdf.move_down 2
    pdf.text "• <b>Riesgo Detectado:</b> #{riesgo}.", size: 9, inline_format: true
    pdf.move_down 6

    # Se usa inline_format: true para procesar el <b>
    pdf.text "<b>CONCLUSIÓN:</b>", size: 9.5, inline_format: true
    pdf.move_down 2

    texto_conclusion = "A la vista de la exploración médica practicada y las circunstancias del/la paciente, se estima que el ingreso residencial resulta una medida necesaria y proporcionada para asegurar su protección e integridad.\n\nPor lo expuesto, el sentido del dictamen es:"
    pdf.text texto_conclusion, size: 9, align: :justify, leading: 2

    pdf.move_down 6

    # Recuadro con el resultado final del dictamen
    pdf.bounding_box([10, pdf.cursor], width: pdf.bounds.width - 20) do
      pdf.stroke_color "000000"
      pdf.line_width 0.6
      pdf.stroke_bounds

      pdf.move_down 5
      pdf.text "<b>#{dictamen.upcase} DEL INTERNAMIENTO INVOLUNTARIO</b>", size: 9, style: :bold, align: :center, inline_format: true
      pdf.move_down 5
    end

    pdf.move_down 10
    pdf.text "Lo que emito e informo a los efectos judiciales oportunos.", size: 8.5, style: :italic

    pdf.move_down 15

    # Bloque de Firma
    pdf.bounding_box([pdf.bounds.width - 180, pdf.cursor], width: 180) do
      pdf.text "El Médico Forense,", size: 9
      pdf.move_down 22
      pdf.text "Fdo.: #{MEDICO}", size: 9, style: :bold
      pdf.text "Nº Col./Reg.: #{colegiado}", size: 8
    end
  end

  # ============================================================
  # MÉTODOS DE BÚSQUEDA Y AUXILIARES
  # ============================================================

  def obtener_valor_flexible(posibles_claves)
    posibles_claves.each do |clave|
      campo = buscar_campo(clave)
      if campo
        valor = @datos[campo.id]
        return formatear_valor(valor) if valor && !valor.to_s.strip.empty?
      end

      # Búsqueda directa en el hash de datos
      valor_directo = @datos[clave] || @datos[clave.to_sym]
      return formatear_valor(valor_directo) if valor_directo && !valor_directo.to_s.strip.empty?
    end

    nil
  end

  def buscar_campo(id)
    return nil unless @tipo.respond_to?(:campos)

    id_limpio = id.to_s.downcase.strip
    @tipo.campos.find do |c|
      nombre_normalizado = c.nombre.to_s.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/^_+|_+$/, "")

      c.id.to_s.downcase.strip == id_limpio || nombre_normalizado == id_limpio
    end
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