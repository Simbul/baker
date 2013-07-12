function moveToParagraph(parNo)
{
	if (parNo < 0)
		return;
	var windowX = window.scrollX;
	var parCount = 0;
	var paragraphs = document.getElementsByTagName('p');
	if (parNo >= paragraphs.length)
		return;
	// window.scrollTo(paragraphs[parNo].offsetLeft,0);
	return paragraphs[parNo].offsetLeft;
}
moveToParagraph(%i);