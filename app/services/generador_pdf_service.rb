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
      # DATOS
      # ========================================================

      generar_datos(pdf)

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

      valor = @datos[campo.id]

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

    else
      valor.to_s

    end
  end
end