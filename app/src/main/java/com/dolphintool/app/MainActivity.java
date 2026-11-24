// SPDX-License-Identifier: GPL-2.0-or-later

package com.dolphintool.app;

import android.app.Activity;
import android.os.Bundle;
import android.content.Intent;
import android.net.Uri;
import android.database.Cursor;
import android.provider.DocumentsContract;
import android.provider.OpenableColumns;
import android.widget.Button;
import android.widget.ProgressBar;
import android.widget.ScrollView;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.widget.LinearLayout.LayoutParams;
import android.widget.LinearLayout;
import android.widget.TextView;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.IOException;

public class MainActivity extends Activity {

    static {
        System.loadLibrary("dolphintool");
    }

    private native String nativeInspect(String path);
    private native String nativeExtract(String input, String output);

    private static final int PICK_IMAGE = 100;
    private static final int PICK_FOLDER = 101;

    private TextView status;
    private TextView fileLabel;
    private ProgressBar progress;
    private Button selectButton;
    private Button extractButton;

    private File imageFile;
    private String gameFolderName = "Wii Game";
    private boolean busy = false;

    private int dp(int value) {
        return (int) (value * getResources().getDisplayMetrics().density + 0.5f);
    }

    private GradientDrawable background(int color, int radius) {
        GradientDrawable shape = new GradientDrawable();
        shape.setColor(color);
        shape.setCornerRadius(dp(radius));
        return shape;
    }

    private TextView text(String value, int size, int color, boolean bold) {
        TextView view = new TextView(this);
        view.setText(value);
        view.setTextSize(size);
        view.setTextColor(color);
        if (bold) view.setTypeface(null, Typeface.BOLD);
        return view;
    }

    @Override
    public void onCreate(Bundle state) {
        super.onCreate(state);

        getWindow().setStatusBarColor(Color.rgb(8, 13, 22));
        getWindow().setNavigationBarColor(Color.rgb(8, 13, 22));

        final int bg = Color.rgb(11, 16, 25);
        final int card = Color.rgb(21, 31, 45);
        final int blue = Color.rgb(38, 116, 221);
        final int white = Color.rgb(243, 247, 255);
        final int muted = Color.rgb(141, 164, 193);

        ScrollView scroll = new ScrollView(this);
        scroll.setFillViewport(true);
        scroll.setBackgroundColor(bg);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(20), dp(28), dp(20), dp(24));
        scroll.addView(root);

        TextView title = text("WiiExtract", 30, white, true);
        root.addView(title);

        TextView subtitle = text("v1.0  ·  Wii Disc Extractor", 13, muted, false);
        LayoutParams subParams = new LayoutParams(-1, -2);
        subParams.topMargin = dp(5);
        subParams.bottomMargin = dp(26);
        root.addView(subtitle, subParams);

        LinearLayout imageCard = new LinearLayout(this);
        imageCard.setOrientation(LinearLayout.VERTICAL);
        imageCard.setPadding(dp(18), dp(20), dp(18), dp(20));
        imageCard.setBackground(background(card, 20));

        TextView imageTitle = text("IMAGEN DE WII", 12, muted, true);
        imageCard.addView(imageTitle);

        fileLabel = text("Ninguna imagen seleccionada", 16, white, true);
        LayoutParams fileParams = new LayoutParams(-1, -2);
        fileParams.topMargin = dp(14);
        fileParams.bottomMargin = dp(16);
        imageCard.addView(fileLabel, fileParams);

        selectButton = new Button(this);
        selectButton.setText("SELECCIONAR ISO / RVZ");
        selectButton.setTextColor(Color.WHITE);
        selectButton.setAllCaps(false);
        selectButton.setBackground(background(blue, 14));
        selectButton.setMinHeight(dp(54));
        selectButton.setOnClickListener(v -> {
            Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
            intent.setType("*/*");
            intent.addCategory(Intent.CATEGORY_OPENABLE);
            startActivityForResult(intent, PICK_IMAGE);
        });
        imageCard.addView(selectButton, new LayoutParams(-1, dp(54)));
        root.addView(imageCard);

        LinearLayout extractCard = new LinearLayout(this);
        extractCard.setOrientation(LinearLayout.VERTICAL);
        extractCard.setPadding(dp(18), dp(20), dp(18), dp(20));
        extractCard.setBackground(background(card, 20));

        LayoutParams extractCardParams = new LayoutParams(-1, -2);
        extractCardParams.topMargin = dp(16);
        root.addView(extractCard, extractCardParams);

        extractCard.addView(text("EXTRACCIÓN", 12, muted, true));

        TextView description = text(
            "Estructura completa para KartPad", 16, white, true);
        LayoutParams descriptionParams = new LayoutParams(-1, -2);
        descriptionParams.topMargin = dp(12);
        extractCard.addView(description, descriptionParams);

        TextView folders = text(
            "📁  files/\n📁  sys/", 15, muted, false);
        folders.setPadding(dp(14), dp(12), dp(14), dp(12));
        folders.setBackground(background(Color.rgb(13, 22, 35), 12));

        LayoutParams foldersParams = new LayoutParams(-1, -2);
        foldersParams.topMargin = dp(14);
        foldersParams.bottomMargin = dp(16);
        extractCard.addView(folders, foldersParams);

        extractButton = new Button(this);
        extractButton.setText("EXTRAER ARCHIVOS");
        extractButton.setTextColor(Color.WHITE);
        extractButton.setAllCaps(false);
        extractButton.setBackground(background(blue, 14));
        extractButton.setMinHeight(dp(54));
        extractButton.setEnabled(false);
        extractButton.setOnClickListener(v -> {
            Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);
            startActivityForResult(intent, PICK_FOLDER);
        });
        extractCard.addView(extractButton, new LayoutParams(-1, dp(54)));

        LinearLayout statusCard = new LinearLayout(this);
        statusCard.setOrientation(LinearLayout.VERTICAL);
        statusCard.setPadding(dp(18), dp(20), dp(18), dp(20));
        statusCard.setBackground(background(card, 20));

        LayoutParams statusParams = new LayoutParams(-1, -2);
        statusParams.topMargin = dp(16);
        root.addView(statusCard, statusParams);

        statusCard.addView(text("ESTADO", 12, muted, true));

        progress = new ProgressBar(this, null,
            android.R.attr.progressBarStyleHorizontal);
        progress.setIndeterminate(true);
        progress.setIndeterminateTintList(
            android.content.res.ColorStateList.valueOf(blue));
        progress.setVisibility(View.GONE);

        LayoutParams progressParams = new LayoutParams(-1, dp(5));
        progressParams.topMargin = dp(14);
        statusCard.addView(progress, progressParams);

        status = text("Seleccioná una ISO o RVZ para comenzar.",
            14, white, false);

        LayoutParams statusTextParams = new LayoutParams(-1, -2);
        statusTextParams.topMargin = dp(14);
        statusCard.addView(status, statusTextParams);

        TextView footer = text(
            "Procesamiento local  ·  ARM64", 12, muted, false);
        footer.setGravity(Gravity.CENTER);

        LayoutParams footerParams = new LayoutParams(-1, -2);
        footerParams.topMargin = dp(28);
        root.addView(footer, footerParams);

        setContentView(scroll);
    }

    private void updateStatus(String message) {
        runOnUiThread(() -> status.setText(message));
    }

    private void setBusy(boolean value) {
        busy = value;
        runOnUiThread(() -> {
            selectButton.setEnabled(!value);
            extractButton.setEnabled(!value && imageFile != null);
            progress.setVisibility(value ? View.VISIBLE : View.GONE);
            selectButton.setAlpha(value ? 0.5f : 1f);
            extractButton.setAlpha(
                (!value && imageFile != null) ? 1f : 0.5f);
        });
    }

    @Override
    protected void onActivityResult(
            int requestCode, int resultCode, Intent data) {

        super.onActivityResult(requestCode, resultCode, data);

        if (resultCode != RESULT_OK || data == null || busy)
            return;

        Uri uri = data.getData();
        if (uri == null)
            return;

        if (requestCode == PICK_IMAGE) {
            gameFolderName = getGameFolderName(uri);
            fileLabel.setText(gameFolderName);
            setBusy(true);
            imageFile = null;

            new Thread(() -> {
                File temp = new File(getCacheDir(), "selected-disc.img");

                try {
                    updateStatus("Copiando imagen temporal...");

                    copyUriToFile(uri, temp);

                    String result = nativeInspect(temp.getAbsolutePath());

                    if (!result.startsWith("Partición DATA encontrada")) {
                        throw new IOException(result);
                    }

                    imageFile = temp;
                    updateStatus(result + "\n\nLista para extraer.");

                } catch (Exception e) {
                    temp.delete();
                    updateStatus("Error: " + e.getMessage());
                } finally {
                    setBusy(false);
                }
            }).start();
        }

        if (requestCode == PICK_FOLDER && imageFile != null) {
            setBusy(true);

            new Thread(() -> {
                File output = new File(getCacheDir(), "data-extracted");
                boolean success = false;

                try {
                    deleteRecursive(output);

                    if (!output.mkdirs())
                        throw new IOException("No se pudo crear carpeta temporal");

                    updateStatus("Extrayendo DATA...");

                    String result = nativeExtract(
                            imageFile.getAbsolutePath(),
                            output.getAbsolutePath()
                    );

                    if (!result.startsWith("Extracción completada.")) {
                        throw new IOException(result);
                    }

                    updateStatus("Copiando archivos al destino...");

                    Uri destination = DocumentsContract.buildDocumentUriUsingTree(
                            uri,
                            DocumentsContract.getTreeDocumentId(uri)
                    );


                    Uri gameFolder = DocumentsContract.createDocument(
                        getContentResolver(),
                        destination,
                        DocumentsContract.Document.MIME_TYPE_DIR,
                        gameFolderName
                    );

                    if (gameFolder == null) {
                        throw new IOException(
                            "No se pudo crear la carpeta del juego"
                        );
                    }

                    copyDirectory(output, gameFolder);


                    success = true;
                    updateStatus(result + "\n\nArchivos copiados correctamente.");

                } catch (Exception e) {
                    updateStatus("Error: " + e.getMessage());
                } finally {
                    if (success) {
                        deleteRecursive(output);
                        imageFile.delete();
                        imageFile = null;
                    }
                    setBusy(false);
                }
            }).start();
        }
    }


    private String getGameFolderName(Uri uri) {
        String name = null;

        try (Cursor cursor = getContentResolver().query(
                uri, new String[]{OpenableColumns.DISPLAY_NAME},
                null, null, null)) {
            if (cursor != null && cursor.moveToFirst()) {
                name = cursor.getString(0);
            }
        } catch (Exception ignored) {
        }

        if (name == null || name.trim().isEmpty()) {
            name = uri.getLastPathSegment();
        }

        if (name == null) {
            name = "Wii Game";
        }

        name = name.replaceAll("(?i)\\.(iso|rvz)$", "");
        name = name.replaceAll("[\\\\/:*?\"<>|\\p{Cntrl}]", "_");
        name = name.trim();

        if (name.isEmpty() || name.equals(".") || name.equals("..")) {
            name = "Wii Game";
        }

        return name;
    }

    private void copyUriToFile(Uri uri, File target) throws IOException {
        try (
            InputStream in = getContentResolver().openInputStream(uri);
            OutputStream out = new FileOutputStream(target)
        ) {
            if (in == null)
                throw new IOException("No se pudo abrir la imagen");

            transfer(in, out);
        }
    }

    private void copyDirectory(File source, Uri destination)
            throws IOException {

        File[] children = source.listFiles();

        if (children == null)
            throw new IOException("No se pudo leer: " + source.getName());

        for (File child : children) {
            if (child.isDirectory()) {
                Uri folder = DocumentsContract.createDocument(
                        getContentResolver(),
                        destination,
                        DocumentsContract.Document.MIME_TYPE_DIR,
                        child.getName()
                );

                if (folder == null)
                    throw new IOException("No se pudo crear: " + child.getName());

                copyDirectory(child, folder);

            } else if (child.isFile()) {
                Uri file = DocumentsContract.createDocument(
                        getContentResolver(),
                        destination,
                        "application/octet-stream",
                        child.getName()
                );

                if (file == null)
                    throw new IOException("No se pudo crear: " + child.getName());

                try (
                    InputStream in = new FileInputStream(child);
                    OutputStream out = getContentResolver().openOutputStream(file, "w")
                ) {
                    if (out == null)
                        throw new IOException("No se pudo escribir: " + child.getName());

                    transfer(in, out);
                }
            }
        }
    }

    private void transfer(InputStream in, OutputStream out)
            throws IOException {

        byte[] buffer = new byte[1024 * 1024];
        int count;

        while ((count = in.read(buffer)) != -1) {
            out.write(buffer, 0, count);
        }
    }

    private void deleteRecursive(File file) {
        if (file.isDirectory()) {
            File[] children = file.listFiles();
            if (children != null) {
                for (File child : children)
                    deleteRecursive(child);
            }
        }
        file.delete();
    }
}
