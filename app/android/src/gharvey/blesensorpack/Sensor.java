package gharvey.blesensorpack;

public class Sensor {
	private String name;
	private float data;
	private String units;
	private boolean enable;
	protected int id;
	
	public Sensor(String name, String units, int identifier) {
		this.name = name;
		this.units = units;
		this.enable = false;
		this.id = identifier;
	}
	
	public void setName(String name) {
		this.name = name;
	}
	
	public String getName() {
		return this.name;
	}
	
	public float getData() {
		return this.data;
	}
	
	public void setData(float value) {
		this.data = value;
	}
	
	public void setUnits(String units) {
		this.units = units;
	}
	
	public String getUnits() {
		return this.units;
	}
	
	public void turnOn() {
		this.enable = true;
	}
	
	public void turnOff() {
		this.enable = false;
	}
	
	public boolean isOn() {
		return this.enable;
	}
}