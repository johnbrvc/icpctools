package org.icpc.tools.contest.model.internal;

import java.awt.image.BufferedImage;
import java.io.File;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import javax.imageio.ImageIO;

import org.icpc.tools.contest.Trace;
import org.icpc.tools.contest.model.IContest;
import org.icpc.tools.contest.model.IContestObject;
import org.icpc.tools.contest.model.IJudgement;
import org.icpc.tools.contest.model.feed.ContestSource;
import org.icpc.tools.contest.model.feed.JSONEncoder;
import org.icpc.tools.contest.model.feed.RelativeTime;
import org.icpc.tools.contest.model.feed.Timestamp;

public abstract class ContestObject implements IContestObject {
	public static final String ID = "id";
	protected static final BufferedImage MISSING_IMAGE = new BufferedImage(1, 1, BufferedImage.TYPE_INT_RGB);
	private static final String SINGLETON_ID = "main";

	protected String id;
	protected static List<String> ignoredProps = new ArrayList<>();

	public ContestObject() {
		// default constructor
	}

	public ContestObject(String id) {
		this.id = id;
	}

	@Override
	public String getId() {
		if (isSingleton())
			return SINGLETON_ID;
		return id;
	}

	protected void setId(String id) {
		this.id = id;
	}

	public boolean isSingleton() {
		return false;
	}

	@Override
	public int hashCode() {
		if (isSingleton())
			return getType().hashCode();
		if (id == null)
			return super.hashCode();
		return id.hashCode();
	}

	@Override
	public boolean equals(Object obj) {
		if (obj == null || !getClass().equals(obj.getClass()))
			return false;

		if (isSingleton() || obj == this)
			return true;

		return id != null && id.equals(((IContestObject) obj).getId());
	}

	@Override
	public IContestObject clone() {
		try {
			@SuppressWarnings("unchecked")
			Class<ContestObject> cl = (Class<ContestObject>) getClass();
			ContestObject co = cl.newInstance();
			Map<String, Object> props = getProperties();
			for (String key : props.keySet())
				co.add(key, props.get(key));

			return co;
		} catch (Exception e) {
			Trace.trace(Trace.ERROR, "Error cloning object", e);
			return null;
		}
	}

	protected static boolean parseBoolean(Object value) {
		if (value instanceof Boolean)
			return (Boolean) value;
		return Boolean.parseBoolean((String) value);
	}

	protected static int parseInt(Object value) {
		if (value instanceof Integer)
			return (Integer) value;
		return Integer.parseInt((String) value);
	}

	protected static long parseLong(Object value) {
		if (value instanceof Long)
			return (Long) value;
		return Long.parseLong((String) value);
	}

	protected static double parseDouble(Object value) {
		if (value instanceof Double)
			return (Double) value;
		return Double.parseDouble((String) value);
	}

	protected static Long parseTimestamp(Object value) throws ParseException {
		return Timestamp.parse((String) value);
	}

	public static long getTime(IContestObject obj) {
		if (obj instanceof TimedEvent) {
			return ((TimedEvent) obj).getTime();
		} else if (obj instanceof IJudgement) {
			IJudgement j = (IJudgement) obj;
			if (j.getEndContestTime() != null)
				return j.getEndTime();
			return j.getStartTime();
		}
		return 0;
	}

	public static int getContestTime(IContestObject obj) {
		if (obj instanceof TimedEvent) {
			return ((TimedEvent) obj).getContestTime();
		} else if (obj instanceof IJudgement) {
			IJudgement j = (IJudgement) obj;
			if (j.getEndContestTime() != null)
				return j.getEndContestTime();
			return j.getStartContestTime();
		}
		return 0;
	}

	protected static Integer parseRelativeTime(Object value) throws ParseException {
		if (value == null || "null".equals(value))
			return null;
		return RelativeTime.parse((String) value);
	}

	protected boolean addImpl(String name, Object value) throws Exception {
		return false;
	}

	public final void add(String name, Object value) {
		try {
			if (ID.equals(name)) {
				id = (String) value;
				return;
			}
			Object value2 = value;
			if (value instanceof FileReferenceList)
				value2 = ((FileReferenceList) value).getJSON();

			if (addImpl(name, value2))
				return;
		} catch (Exception e) {
			Trace.trace(Trace.ERROR,
					"Error adding property: " + IContestObject.getTypeName(getType()) + "/" + name + ":" + value, e);
			return;
		}

		String message = "Unknown property ignored: " + IContestObject.getTypeName(getType()) + "/" + name;
		if (ignoredProps.contains(message))
			return;
		Trace.trace(Trace.WARNING, message);
		ignoredProps.add(message);
	}

	protected void getPropertiesImpl(Map<String, Object> props) {
		props.put(ID, id);
	}

	@Override
	public final Object getProperty(String s) {
		if (s == null)
			return null;

		return getProperties().get(s);
	}

	@Override
	public final Map<String, Object> getProperties() {
		Map<String, Object> props = new SimpleMap();
		getPropertiesImpl(props);
		return props;
	}

	public void write(JSONEncoder je) {
		// do nothing
	}

	@Override
	public List<String> validate(IContest c) {
		List<String> errors = new ArrayList<>();

		if ((id == null || id.isEmpty()) && !isSingleton())
			errors.add("Invalid id " + id);

		return errors;
	}

	protected File getFile(FileReference ref, String property, boolean force) {
		if (ref == null)
			return null;

		if (ref.file != null && ref.file.exists()) {
			return ref.file;
		}

		if (!force)
			return null;

		try {
			synchronized (ref) {
				if (ref.file != null && ref.file.exists())
					return ref.file;
				return ContestSource.getInstance().getFile(this, ref, property);
			}
		} catch (Exception e) {
			return null;
		}
	}

	public interface ReferenceMatcher {
		public FileReference getBestMatch(FileReferenceList list);
	}

	/**
	 * Finds the best image where at least one dimension is as big as the given width and height. If
	 * there is no image big enough, the next largest image is returned. For now, assume all images
	 * have similar aspect ratio.
	 */
	protected class ImageSizeFit implements ReferenceMatcher {
		private int width;
		private int height;

		public ImageSizeFit(int width, int height) {
			this.width = width;
			this.height = height;
		}

		@Override
		public FileReference getBestMatch(FileReferenceList list) {
			FileReference bestRef = null;
			for (FileReference ref : list) {
				if (bestRef == null)
					bestRef = ref;
				else {
					if (bestRef.width < width && bestRef.height < height) {
						// current best image is too small - is this one better (larger than current)?
						if (ref.width > bestRef.width || ref.height > bestRef.height)
							bestRef = ref;
					} else if (bestRef.width > width && bestRef.height > height) {
						// current image is too big - is this one better (smaller but still big enough)?
						if (ref.width < bestRef.width || ref.height < bestRef.height) {
							if (ref.width >= width || ref.height >= height)
								bestRef = ref;
						}
					}
				}
			}
			/*if (list.size() > 1) {
				System.out.println("Wanted: " + width + "x" + height + " found: " + bestRef.width + "x" + bestRef.height);
				for (FileReference ref : list) {
					System.out.println("   " + ref.width + "x" + ref.height);
				}
			}*/
			return bestRef;
		}
	}

	protected FileReference getBestFileReference(FileReferenceList list, ReferenceMatcher fit) {
		if (list == null || list.isEmpty())
			return null;

		if (list.size() == 1)
			return list.first();

		if (fit != null)
			return fit.getBestMatch(list);

		return list.first();
	}

	public BufferedImage getRefImage(String property, FileReferenceList list, int width, int height, boolean forceLoad,
			boolean resizeToFit) {
		BufferedImage img = null;

		FileReference ref = getBestFileReference(list, new ImageSizeFit(width, height));
		if (ref == null)
			return null;

		if (ref.data != null)
			img = (BufferedImage) ref.data;
		else if (forceLoad) {
			img = loadImage(getFile(ref, property, true));
			if (img == null)
				img = MISSING_IMAGE;
			ref.data = img;
		}

		if (img == MISSING_IMAGE)
			return null;
		if (resizeToFit)
			return ImageScaler.scaleImage(img, width, height);
		return img;
	}

	protected BufferedImage loadImage(File f) {
		if (f == null || !f.exists())
			return null;

		try {
			return ImageIO.read(f);
		} catch (Exception e) {
			return null;
		}
	}

	@Override
	public String toString() {
		StringBuilder sb = new StringBuilder();
		sb.append(IContestObject.getTypeName(getType()) + "\n");
		Map<String, Object> props = getProperties();
		for (String key : props.keySet())
			sb.append("  " + key + ": " + props.get(key) + "\n");

		sb.deleteCharAt(sb.length() - 1);

		return sb.toString();
	}
}