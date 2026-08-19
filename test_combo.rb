require "bundler/setup"
require "gtk4"

app = Gtk::Application.new(
  "com.generadorinformes.combo-test",
  :flags_none
)

app.signal_connect("activate") do |application|
  window = Gtk::ApplicationWindow.new(application)

  window.title = "Prueba ComboBox"
  window.set_default_size(500, 250)

  box = Gtk::Box.new(:vertical, 20)
  box.margin_top = 40
  box.margin_bottom = 40
  box.margin_start = 40
  box.margin_end = 40

  combo = Gtk::ComboBoxText.new

  combo.append("ventas", "Informe de ventas")
  combo.append("clientes", "Informe de clientes")
  combo.append("proveedores", "Informe de proveedores")

  combo.active = 0

  resultado = Gtk::Label.new("Informe de ventas")

  combo.signal_connect("changed") do
    resultado.text = combo.active_text
    puts "Seleccionado: #{combo.active_text}"
  end

  box.append(Gtk::Label.new("Tipo de informe:"))
  box.append(combo)
  box.append(resultado)

  window.child = box
  window.present
end

app.run
