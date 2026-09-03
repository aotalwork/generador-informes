require "prawn"
require "prawn/table"
require "fileutils"
require "time"

class GeneradorPdfService

  MEDICO = "JUAN POLO LÓPEZ"

  def initialize(tipo, datos)
    @tipo = tipo
    @datos = datos
  end

  def generar(ruta)
    FileUtils.mkdir_p(File.dirname(ruta))

    Prawn::Document.generate(
      ruta,
      page_size: "A4",
      margin: [45, 50, 50, 50]
    ) do |pdf|

      # ========================================================
      # CONFIGURACIÓN
      # ========================================================

      pdf.font_size = 10

      # ========================================================
      # CABECERA
      # ========================================================

      generar_cabecera(pdf)

      # ========================================================
      # DATOS GENERALES
      # ========================================================

      generar_datos(pdf)

      # ========================================================
      # EXPLORACIÓN PSIQUIÁTRICA
      # ========================================================

      generar_exploracion_psiquiatrica(pdf)

      # ========================================================
      # PIE
      # ========================================================

      generar_pie(pdf)
    end

    ruta
  end

  private

  # ============================================================
  # CABECERA
  # ============================================================

  def generar_cabecera(pdf)

    ruta_logo = File.expand_path(
      "../../assets/logo.png",
      __dir__
    )

    # ----------------------------------------------------------
    # LOGO + IDENTIDAD
    # ----------------------------------------------------------

    if File.exist?(ruta_logo)

      pdf.image(
        ruta_logo,
        width: 70,
        height: 70,
        position: :left
      )

      pdf.move_up 58

    end

    pdf.indent(85) do

      pdf.text(
        "PYR",
        size: 12,
        style: :bold
      )

      pdf.move_down 3

      pdf.text(
        "Generador",
        size: 9,
        color: "667085"
      )

    end

    pdf.move_down 30

    # ----------------------------------------------------------
    # LÍNEA
    # ----------------------------------------------------------

    pdf.stroke_color "D0D5DD"
    pdf.line_width = 1
    pdf.stroke_horizontal_rule

    pdf.move_down 20

    # ----------------------------------------------------------
    # MÉDICO
    # ----------------------------------------------------------

    pdf.text(
      "MÉDICO",
      size: 9,
      style: :bold,
      color: "667085"
    )

    pdf.move_down 3

    pdf.text(
      MEDICO,
      size: 13,
      style: :bold,
      color: "1D2939"
    )

    pdf.move_down 18

    # ----------------------------------------------------------
    # TÍTULO DEL INFORME
    # ----------------------------------------------------------

    pdf.text(
      @tipo.nombre,
      size: 22,
      style: :bold,
      color: "1D2939"
    )

    pdf.move_down 7

    # ----------------------------------------------------------
    # DESCRIPCIÓN
    # ----------------------------------------------------------

    unless @tipo.descripcion.to_s.strip.empty?

      pdf.text(
        @tipo.descripcion,
        size: 10,
        color: "667085"
      )

      pdf.move_down 15

    end

    # ----------------------------------------------------------
    # INFORMACIÓN DEL INFORME
    # ----------------------------------------------------------

    informacion = [
      [
        "TIPO",
        @tipo.id.to_s
      ],
      [
        "VERSIÓN",
        @tipo.version.to_s
      ],
      [
        "FECHA DE GENERACIÓN",
        Time.now.strftime("%d/%m/%Y %H:%M")
      ]
    ]

    pdf.table(
      informacion,
      width: pdf.bounds.width,
      cell_style: {
        borders: [],
        padding: [5, 8],
        size: 9
      }
    ) do

      columns(0).font_style = :bold
      columns(0).text_color = "667085"
      columns(1).text_color = "344054"

    end

    pdf.move_down 20

    # ----------------------------------------------------------
    # SEPARADOR
    # ----------------------------------------------------------

    pdf.stroke_color "D0D5DD"
    pdf.stroke_horizontal_rule

    pdf.move_down 20
  end

  # ============================================================
  # DATOS DEL INFORME
  # ============================================================

  def generar_datos(pdf)

    filas = []

    @tipo.campos.each do |campo|

      # --------------------------------------------------------
      # NO MOSTRAR LAS PREGUNTAS AQUÍ
      # --------------------------------------------------------
      #
      # Las preguntas 1-10 se mostrarán posteriormente como
      # texto dentro de EXPLORACIÓN PSIQUIÁTRICA.
      #

      next if campo_pregunta_psiquiatrica?(campo)

      valor = @datos[campo.id]

      # Si es una sección, no la mostramos como una fila
      next if campo_seccion?(campo)

      filas << [
        campo.nombre.to_s,
        formatear_valor(valor)
      ]

    end

    return if filas.empty?

    pdf.table(
      filas,
      width: pdf.bounds.width,
      cell_style: {
        padding: [9, 10],
        borders: [:bottom],
        border_color: "E4E7EC",
        size: 10,
        text_color: "344054"
      }
    ) do

      # --------------------------------------------------------
      # COLUMNA DE NOMBRES
      # --------------------------------------------------------

      columns(0).font_style = :bold
      columns(0).text_color = "1D2939"
      columns(0).width = 150

      # --------------------------------------------------------
      # ALTERNANCIA DE FILAS
      # --------------------------------------------------------

      rows(0..-1).each_with_index do |fila, indice|

        if indice.even?

          fila.background_color = "F8FAFC"

        else

          fila.background_color = "FFFFFF"

        end

      end

    end

    pdf.move_down 20
  end

  # ============================================================
  # EXPLORACIÓN PSIQUIÁTRICA
  # ============================================================

  def generar_exploracion_psiquiatrica(pdf)

    frases = []

    # ----------------------------------------------------------
    # BUSCAR PREGUNTAS 1-10
    # ----------------------------------------------------------

    (1..10).each do |numero|

      id = "pregunta_#{numero}"

      campo = buscar_campo(id)

      next unless campo

      valor = @datos[campo.id]

      next if valor.nil?

      frase = obtener_frase(campo, valor)

      next if frase.to_s.strip.empty?

      frases << frase.to_s.strip

    end

    # ----------------------------------------------------------
    # SI NO HAY FRASES, NO MOSTRAMOS LA SECCIÓN
    # ----------------------------------------------------------

    return if frases.empty?

    # ----------------------------------------------------------
    # TÍTULO
    # ----------------------------------------------------------

    pdf.text(
      "EXPLORACIÓN PSIQUIÁTRICA",
      size: 13,
      style: :bold,
      color: "1D2939"
    )

    pdf.move_down 8

    # ----------------------------------------------------------
    # TEXTO GENERADO
    # ----------------------------------------------------------

    pdf.text(
      frases.join(" "),
      size: 10,
      leading: 4,
      color: "344054",
      align: :justify
    )

    pdf.move_down 20
  end

  # ============================================================
  # BUSCAR CAMPO
  # ============================================================

  def buscar_campo(id)

    @tipo.campos.find do |campo|
      campo.id.to_s == id.to_s
    end

  end

  # ============================================================
  # COMPROBAR SI ES UNA PREGUNTA PSIQUIÁTRICA
  # ============================================================

  def campo_pregunta_psiquiatrica?(campo)

    id = campo.id.to_s

    id.match?(/\Apregunta_[1-9][0-9]?\z/)

  end

  # ============================================================
  # COMPROBAR SI ES UNA SECCIÓN
  # ============================================================

  def campo_seccion?(campo)

    campo.respond_to?(:tipo) &&
      campo.tipo.to_s == "seccion"

  end

  # ============================================================
  # OBTENER FRASE SEGÚN RESPUESTA
  # ============================================================

  def obtener_frase(campo, valor)

    return "" if valor.nil?

    # ----------------------------------------------------------
    # SI EL CAMPO NO TIENE FRASES
    # ----------------------------------------------------------

    unless campo.respond_to?(:frases) && campo.frases

      return formatear_valor(valor)

    end

    frases = campo.frases

    # ----------------------------------------------------------
    # INTENTAMOS ENCONTRAR LA RESPUESTA
    # ----------------------------------------------------------
    #
    # Dependiendo de cómo se cargue YAML, la clave puede ser:
    #
    # Integer -> 1
    # String  -> "1"
    #

    frase =
      frases[valor] ||
      frases[valor.to_s]

    # ----------------------------------------------------------
    # SI NO EXISTE LA FRASE
    # ----------------------------------------------------------

    return formatear_valor(valor) if frase.nil?

    frase.to_s

  end

  # ============================================================
  # PIE DE PÁGINA
  # ============================================================

  def generar_pie(pdf)

    pdf.number_pages(
      "Página <page> de <total>",
      at: [pdf.bounds.right - 90, 20],
      size: 8,
      color: "98A2B3"
    )

    pdf.repeat(:all) do

      pdf.stroke_color "E4E7EC"

      pdf.line_width = 0.5

      pdf.horizontal_line(
        0,
        pdf.bounds.width,
        at: 28
      )

      pdf.text_box(
        "Generador",
        at: [0, 20],
        width: pdf.bounds.width,
        height: 12,
        size: 8,
        color: "98A2B3",
        align: :left
      )

    end
  end

  # ============================================================
  # FORMATEAR VALORES
  # ============================================================

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